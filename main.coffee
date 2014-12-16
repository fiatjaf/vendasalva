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

# the model and handles
theState = ->
  hg.state
    activeTab: hg.value 'Input'
    activeDay: hg.value (new Date).toISOString().split('T')[0]
    couchURL: hg.value localStorage.getItem('couchURL') or ''
    rawInput: hg.value ''
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

    handles:
      changeTab: (state, data) -> state.activeTab.set data # data is the tabname itself
      saveInputText: (state, data) ->
        store.get(state.activeDay).then((doc) ->
          if not doc
            doc = {_id: state.activeDay}
          doc.raw = state.rawInput
          store.save doc
        )

      showDaysList: (state, data) ->
        store.listDays().then((daysList) ->
          state.daysList.set daysList
          state.activeTab.set 'Dias'
        )
      goToDay: (state, data) -> # data is the day itself, as a string
        store.get(data).catch(->
          state.activeDay.set data
          state.activeTab.set 'Input'
        ).then((doc) ->
          state.rawInput.set doc.raw
          state.activeDay.set doc._id
          state.activeTab.set 'Input'
        )
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
        syncing = store.sync(state.couchURL)
        console.log 'replication started'
        syncing.on 'change', (info) -> console.log 'change', info
        syncing.on 'error', (info) -> console.log 'error', info
        syncing.on 'complete', (info) =>
          console.log 'replication complete', info
          localStorage.setItem 'couchURL', state.couchURL

vrenderMain = (state) ->
  vrenderChosen = tabs[state.activeTab or 'Input']

  (div id: 'main',
    (nav {},
      (div className: 'menu',
        (a
          href: '#'
          value: 'Input'
          'ev-click': hg.clickEvent state.handles.changeTab, 'Input'
        , 'Lançamentos')
        (a
          href: '#'
          value: 'Dias'
          'ev-click': hg.clickEvent state.handles.showDaysList
        , 'Dias')
      )
      (button
        'ev-click': hg.clickEvent state.handles.sync
      , 'SYNC')
      (vrenderSearch state)
    )
    (div id: 'container',
      (vrenderChosen state)
    )
  )

vrenderSearch = (state) ->
  (input
    'ev-input': hg.changeEvent state.handles.search
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
        'ev-click': hg.clickEvent state.handles.showItemData
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
            'ev-click': hg.clickEvent state.handles.goToDay, day.day
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
                 'ev-click': hg.clickEvent state.handles.goToDay, event.id
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

# standalone handles
externalHandles = ((state) ->
  inputTextChanged: (data) -> state.rawInput.set data.cm.getValue()
)(state)

tabs =
  'Input': Input externalHandles
  'Dias': vrenderDias
  'SearchResults': vrenderSearchResults
  'Item': vrenderItem

# run
hg.app document.body, state, vrenderMain
