Promise  = require 'lie'

store    = require './store'
parse    = require './parse'
nextTick = if setImmediate then setImmediate else (fn) -> setTimeout(fn, 0)
{sync, getRemoteCouch} = require './sync'

handlers =
  changeTab: (State, data) ->
    # data is the tabname itself
    State.change 'activeTab', data

  showDaysList: (State, data) ->
    store.listDays().then((daysList) ->
      State.change
        daysList: daysList
        activeTab: 'Dias'
    ).catch(console.log.bind @)

  goToDay: (State, data) ->
    # data is the day itself, as a string
    @updateDay data
    State.change 'activeTab', 'Input'

  search: (State, data) ->
    State.updateSilently 'forcedSearchValue', ''

    results = store.searchItem data.term
    if results.length
      if results.length < 7
        Promise.all((store.grabItemData i.ref for i in results))
        .then((items) ->
          State.change
            searchResults: items
            activeTab: 'SearchResults'
        )
      else
        State.change
          searchResults: results
          activeTab: 'SearchResults'

  forceSearch: (State, data) -> State.change 'forcedSearchValue', data

  handleSync: -> if localStorage.getItem 'remoteCouch' then sync(true) else getRemoteCouch()

  saveInputText: (State, data) ->
    activeDay = State.get 'activeDay'
    store.get(activeDay).then((doc) ->
      if not doc
        doc = {_id: activeDay}
      doc.raw = State.get 'rawInput'
      store.save(doc)
    ).then(->
      localStorage.removeItem activeDay + ':raw'
      localStorage.removeItem activeDay + ':rev_number'
      State.silentlyUpdate 'usingLocalCache', false
    ).catch(console.log.bind @)

  updateDay:  (State, day) ->
    store.get(day).then((doc) ->
      raw = @checkLocalCache day, doc

      State.change
        input:
          rawInput: raw
          activeDay: day
    ).catch(console.log.bind @)

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

  checkLocalCache: (State, day, doc) ->
    local_raw = localStorage.getItem day + ':raw'
    doc_rev = if doc then parseInt(doc._rev.split('-')[0]) else 0
  
    # everything only matters if there is a cached version
    if local_raw
      local_rev = parseInt(localStorage.getItem day + ':rev_number') or 0
  
      # we override it if the pouchdb version is newer
      if doc and doc_rev > local_rev
        raw = doc.raw
        State.silentlyUpdate 'usingLocalCache', false
        localStorage.setItem day + ':raw', ''
        localStorage.setItem day + ':rev_number', doc_rev
  
      # otherwise we keep using it
      else
        State.silentlyUpdate 'usingLocalCache', true
        raw = local_raw
  
    # if we don't have any cache, use the pouchdb doc
    # and init the cache (doc_rev will be 0)
    else if doc
      raw = doc.raw
      State.silentlyUpdate 'usingLocalCache', false
      localStorage.setItem day + ':rev_number', doc_rev
  
    # or start a new thing
    else
      raw = ''
      State.silentlyUpdate 'usingLocalCache', false
      localStorage.setItem day + ':rev_number', 0
  
    return raw
  
    # parse asynchronously
    nextTick ->
      State.change
        parsedInput: parse rawInput

module.exports = handlers
