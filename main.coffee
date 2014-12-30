hg               = require 'mercury'
Reais            = require 'reais'
Titulo           = require('titulo').toLaxTitleCase

store            = require './store.coffee'
vrenderTable     = require './vrender-table.coffee'
Input            = require './component-input.coffee'

{div, span, pre, nav,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

# the model and channels
goToDay = (state, day) ->
  store.get(day).then((doc) ->
    local_raw = localStorage.getItem day + ':raw'
    doc_rev = if doc then parseInt(doc._rev.split('-')[0]) else 0

    # everything only matters if there is a cached version
    if local_raw
      local_rev = parseInt(localStorage.getItem day + ':rev_number') or 0

      # we override it if the pouchdb version is newer
      if doc and doc_rev > local_rev
        raw = doc.raw
        state.usingLocalCache.set false
        localStorage.setItem day + ':raw', ''
        localStorage.setItem day + ':rev_number', doc_rev

      # otherwise we keep using it
      else
        state.usingLocalCache.set true
        raw = local_raw

    # if we don't have any cache, use the pouchdb doc
    # and init the cache (doc_rev will be 0)
    else if doc
      raw = doc.raw
      state.usingLocalCache.set false
      localStorage.setItem day + ':rev_number', doc_rev

    # or start a new thing
    else
      raw = ''
      state.usingLocalCache.set false
      localStorage.setItem day + ':rev_number', 0

    state.rawInput.set raw
    state.activeDay.set day
    state.activeTab.set 'Input'
  )

theState = ->
  hg.state
    activeTab: hg.value 'Input'
    activeDay: hg.value (new Date).toISOString().split('T')[0]
    rawInput: hg.value ''
    usingLocalCache: hg.value false
    parsedData: hg.struct
      vendas: hg.array []
      compras: hg.array []
      contas: hg.array []
      comments: hg.array []
      caixa: hg.array [{desc: 'Vendas', value: 0}]
      receita: hg.value 0
    daysList: hg.value []
    searchResults: hg.value []
    itemData: hg.value {}

    channels:
      changeTab: (state, data) -> state.activeTab.set data # data is the tabname itself
      saveInputText: (state, data) ->
        activeDay = state.activeDay()
        store.get(activeDay).then((doc) ->
          if not doc
            doc = {_id: activeDay}
          doc.raw = state.rawInput()
          store.save(doc).then(->
            localStorage.removeItem activeDay + ':raw'
            localStorage.removeItem activeDay + ':rev_number'
            state.usingLocalCache.set false
          )
        )

      showDaysList: (state, data) ->
        store.listDays().then((daysList) ->
          state.daysList.set daysList
          state.activeTab.set 'Dias'
        )
      goToDay: (state, data) -> goToDay state, data # data is the day itself, as a string
      showItemData: (state, data) ->
        store.grabItemData(item).then((itemData) ->
          state.itemData.set itemData
          state.activeTab.set 'Item'
        )
      search: (state, data) ->
        results = store.searchItem data.term
        if results.length
          state.searchResults.set results
          state.activeTab.set 'SearchResults'
      sync: (state, data) ->
        # set callback to be called by the popup window
        window.passDB = (couchURL) ->
          opened.close()
          syncing = store.sync(couchURL)
          console.log 'replication started'
          syncing.on 'change', (info) -> console.log 'change', info
          syncing.on 'error', (info) -> console.log 'error', info
          syncing.on 'complete', (info) ->
            console.log 'replication complete', info

        # open the popup
        opened = window.open(
          '/popup.html',
          '_blank',
          'height=400, width=550'
        )

vrenderMain = (state) ->
  vrenderChosen = tabs[state.activeTab or 'Input']

  (div id: 'main',
    (nav {},
      (div className: 'menu',
        (a
          href: '#'
          value: 'Input'
          'ev-click': hg.sendClick state.channels.changeTab, 'Input'
        , 'Lançamentos')
        (a
          href: '#'
          value: 'Dias'
          'ev-click': hg.sendClick state.channels.showDaysList
        , 'Dias')
      )
      (button
        'ev-click': hg.sendClick state.channels.sync
      , 'SYNC')
      (vrenderSearch state)
    )
    (div id: 'container',
      (vrenderChosen state)
    )
  )

vrenderSearch = (state) ->
  (input
    'ev-input': hg.sendChange state.channels.search
    name: 'term'
    type: 'text'
    attributes:
      placeholder: 'Procurar produtos'
  )

vrenderSearchResults = (state) ->
  (ul {},
    (li {},
      (a
        href: '#'
        'ev-click': hg.sendClick state.channels.showItemData
      , r)
    ) for r in state.searchResults
  )

vrenderDias = (state) ->
  (table id: 'dias',
    (thead {},
      (tr {},
        (th {}, 'Dia')
        (th {}, 'Total vendido')
      )
    )
    (tbody {},
      (tr {},
        (td {},
          (a
            href: "##{day.day}"
            value: day.day
            'ev-click': hg.sendClick state.channels.goToDay, day.day
          , "#{day.day.split('-').reverse().join('/')}")
        )
        (td {}, "R$ #{Reais.fromInteger day.receita}")
      ) for day in state.daysList
    )
  )

vrenderItem = (state) ->
  (div id: 'item',
    (h1 {}, Titulo state.itemData.name)
    (div {},
      (div className: 'fourth',
        (div className: 'display-box',
          (h3 {className: 'label'}, 'EM ESTOQUE')
          (h2 {className: 'value'}, '' + state.itemData.stock)
        ) if state.itemData.stock
      )
      (div className: 'fourth',
        (div className: 'display-box',
          (h3 {className: 'label'}, 'R$')
          (h2 {className: 'value'}, Reais.fromInteger state.itemData.price)
        ) if state.itemData.price
      )
      (div className: 'half',
        (table id: 'events',
          (thead {},
            (tr {},
              (th {}, 'Dia')
              (th {}, 'Q')
              (th {}, 'R$')
              (th {})
            )
          )
          (tbody {},
            (tr {},
              (td {},
               (a
                 href: "##{event.id}"
                 value: event.id
                 'ev-click': hg.sendClick state.channels.goToDay, event.id
               , event.day)
              )
              (td {}, '' + event.q + ' ' + event.u)
              (td {}, 'R$ ' + Reais.fromInteger event.p + ' por ' + event.u)
              (td {}, if event.compra then '(compra)' else '')
            ) for event in state.itemData.events
          )
        )
      )
    )
  )

state = theState()

# startup functions
(->
  goToDay state, state.activeDay()
)()

# standalone channels
externalHandles = ((state) ->
  inputTextChanged: (data) ->
    activeDay = state.activeDay()
    rawInput = data.cm.getValue()
    return if rawInput == state.rawInput()

    localStorage.setItem activeDay + ':raw', rawInput
    state.usingLocalCache.set true
    state.rawInput.set rawInput
)(state)

tabs =
  'Input': Input(externalHandles)
  'Dias': vrenderDias
  'SearchResults': vrenderSearchResults
  'Item': vrenderItem

# run
hg.app document.body, state, vrenderMain
