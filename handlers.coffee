Promise    = require 'lie'
superagent = (require 'superagent-promise')(require('superagent'), Promise)

store    = require './store'
parse    = require './parse'
nextTick = if setImmediate then setImmediate else (fn) -> setTimeout(fn, 0)

handlers =
  changeTab: (State, data) ->
    # data is the tabname itself
    State.change 'activeTab', data

  showDaysList: (State, data) ->
    @changeTab State, 'dias'
    store.listDays().then((daysList) ->
      State.change 'dias.list', daysList
    ).catch(console.log.bind console)

  calcResumo: (State) ->
    @changeTab State, 'resumo'
    store.topSales().then((overall) ->
      State.change
        resumo:
          top:
            overall: overall
    )

  goToDay: (State, data) ->
    # data is the day itself, as a string
    @updateDay(State, data).then(->
      State.change 'activeTab', 'input'
    )

  search: (State, data) ->
    State.silentlyUpdate 'forcedSearchValue', ''

    results = store.searchItem data.term
    if results.length
      if results.length < 7
        Promise.all((store.grabItemData i.ref for i in results))
        .then((items) ->
          State.change
            searchresults:
              results: -> items
            activeTab: 'searchresults'
        ).catch(console.log.bind console)
      else
        State.change
          searchresults:
            results: -> results
          activeTab: 'searchresults'

  forceSearch: (State, data) -> State.change 'forcedSearchValue', data

  sync: (State, force=false) ->
    lastSync = localStorage.getItem 'lastSync'
    if force or not lastSync or parseInt(lastSync) + 3600 < parseInt(Date.now()/1000)
      # sync once an hour
      Promise.resolve().then(->
      ).then((res) ->
        logged = State.get 'loggedAs'
        if logged
          return logged
        else
          return superagent.get("https://vendasalva.smileupps.com/_session")
            .set('Accept': 'application/json')
            .withCredentials()
            .end()
          .then((res) ->
            # userCtx.name is null when no one is logged
            State.silentlyUpdate 'loggedAs', res.body.userCtx.name
            return res.body.userCtx.name
          )
      ).then((userName) ->
        if not userName
          console.log 'not logged, will not sync.'
          return

        console.log 'syncing as ' + userName
        couchURL = 'https://vendasalva.smileupps.com/vs-' + userName
        localStorage.setItem 'lastSync', parseInt(Date.now()/1000)

        store.changeLocalPouch(userName)
        syncing = store.sync(couchURL)
        console.log 'replication started'
        State.change 'syncing', true

        syncing.on 'change', (info) -> console.log 'change', info
        syncing.on 'error', (info) -> console.log 'error', info
        syncing.on 'complete', (info) ->
          console.log 'replication complete', info
          State.change 'syncing', false
      ).catch(console.log.bind console)

  handleSync: (State) ->
    here = @
    Promise.resolve().then(->
      superagent.get("https://vendasalva.smileupps.com/_session")
        .set('Accept': 'application/json')
        .withCredentials()
        .end()
    ).then((res) ->
      if res.body.userCtx.name == store.pouchName or store.pouchName == 'vendasalva'
        console.log "logged as #{res.body.userCtx.name}, will sync."
        here.sync State, true
      else
        return State.change 'modalOpened', 'auth'
    ).catch(console.log.bind console)

  login: (State, data) ->
    here = @
    Promise.resolve().then(->
      superagent.post("https://vendasalva.smileupps.com/_session")
        .set('Accept': 'application/json')
        .send(data)
        .withCredentials()
        .end()
    ).then((res) ->
      console.log "logged as #{res.body.name}"
      State.silentlyUpdate 'loggedAs', res.body.name
      here.sync State, true
      here.closeModal State
    ).catch(console.log.bind console)

  checkLoginStatus: (State) ->
    superagent.get("https://vendasalva.smileupps.com/_session")
      .set('Accept': 'application/json')
      .withCredentials()
      .end()
    .then((res) ->
      # userCtx.name is null when no one is logged
      State.change 'loggedAs', res.body.userCtx.name
    )

  changeLocalAccount: (State, data) ->
    if not data.pouchName
      State.change 'modalOpened', 'localaccount'
    else
      store.changeLocalPouch(data.pouchName)
      @closeModal State

  closeModal: (State) -> State.change 'modalOpened', null
      
  saveInputText: (State, data) ->
    activeDay = State.get 'input.activeDay'
    store.get(activeDay).then((doc) ->
      if not doc
        doc = {_id: activeDay}
      doc.raw = State.get 'input.rawInput'
      store.save(doc)
    ).then(->
      localStorage.removeItem activeDay + ':raw'
      localStorage.removeItem activeDay + ':rev_number'
      State.change 'input.usingLocalCache', false
    ).catch(console.log.bind console)

  updateDay:  (State, day) ->
    here = @
    store.get(day).then((doc) ->
      raw = here.checkLocalCache State, day, doc
      State.change
        input:
          rawInput: raw
          activeDay: day
      # parse asynchronously
      nextTick ->
        State.change 'input.parsedInput', parse raw
    ).catch(console.log.bind console)

  inputTextChanged: (State, cmData) ->
    # only react to big events (newline, big deletions, multiline pastes)
    if cmData.ev
      ev = cmData.ev[0]
      if ev.text.length < 2 and ev.removed.length < 2
        return
  
    rawInput = cmData.cm.getValue()
    return if rawInput == State.get 'input.rawInput'
  
    activeDay = State.get 'input.activeDay'
    localStorage.setItem activeDay + ':raw', rawInput

    State.change
      input:
        usingLocalCache: true
        rawInput: rawInput
    # parse asynchronously
    nextTick ->
      State.change 'input.parsedInput', parse rawInput

  checkLocalCache: (State, day, doc) ->
    local_raw = localStorage.getItem day + ':raw'
    doc_rev = if doc then parseInt(doc._rev.split('-')[0]) else 0
  
    # everything only matters if there is a cached version
    if local_raw
      local_rev = parseInt(localStorage.getItem day + ':rev_number') or 0
  
      # we override it if the pouchdb version is newer
      if doc and doc_rev > local_rev
        raw = doc.raw
        State.silentlyUpdate 'input.usingLocalCache', false
        localStorage.setItem day + ':raw', ''
        localStorage.setItem day + ':rev_number', doc_rev
  
      # otherwise we keep using it
      else
        State.silentlyUpdate 'input.usingLocalCache', true
        raw = local_raw
  
    # if we don't have any cache, use the pouchdb doc
    # and init the cache (doc_rev will be 0)
    else if doc
      raw = doc.raw or ''
      State.silentlyUpdate 'input.usingLocalCache', false
      localStorage.setItem day + ':rev_number', doc_rev
  
    # or start a new thing
    else
      raw = ''
      State.silentlyUpdate 'input.usingLocalCache', false
      localStorage.setItem day + ':rev_number', 0

    return raw

module.exports = handlers
