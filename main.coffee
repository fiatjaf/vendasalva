hg               = require 'mercury'
Reais            = require 'reais'
Titulo           = require('titulo').toLaxTitleCase
date             = require 'date-extended'

store            = require './store.coffee'
vrenderTable     = require './vrender-table.coffee'
Input            = require './component-input.coffee'

Offline.options = {
  checks:
    image:
      url: 'https://secure.gravatar.com/avatar/b760f503c84d1bf47322f401066c753f?d=blank&s=20'
    active: 'image'
  checkOnLoad: true
  interceptRequests: false
  requests: false
}

{div, span, pre, nav,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

# the model and channels
setDay = (state, day) ->
  state.InputState.customHandlers.updateDay()(day)
  state.activeTab.set 'Input'

sync = ->
  lastSync = localStorage.getItem 'lastSync'
  if not lastSync or parseInt(lastSync) + 3600 < parseInt(Date.now()/1000)
    # sync once an hour
    localStorage.setItem 'lastSync', parseInt(Date.now()/1000)
    couchURL = localStorage.getItem 'remoteCouch'
    if not couchURL
      console.log 'no couchURL, will not sync'
      return
    console.log 'got couchURL from localStorage, will sync: ' + couchURL
    syncing = store.sync(couchURL)
    console.log 'replication started'
    syncing.on 'change', (info) -> console.log 'change', info
    syncing.on 'error', (info) -> console.log 'error', info
    syncing.on 'complete', (info) ->
      console.log 'replication complete', info

theState = ->
  state = hg.state
    activeTab: hg.value 'Input'
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

    InputState: Input()

    channels:
      changeTab: (state, data) -> state.activeTab.set data # data is the tabname itself
      showDaysList: (state, data) ->
        store.listDays().then((daysList) ->
          state.daysList.set daysList
          state.activeTab.set 'Dias'
        )
      goToDay: (state, data) -> setDay state, data # data is the day itself, as a string
      showItemData: (state, data) ->
        store.grabItemData(data).then((itemData) ->
          state.itemData.set itemData
          state.activeTab.set 'Item'
        )
      search: (state, data) ->
        results = store.searchItem data.term
        if results.length
          state.searchResults.set results
          state.activeTab.set 'SearchResults'
      getRemoteCouch: (state, data) ->
        # set callback to be called by the popup window
        window.passDB = (couchURL) ->
          # when called, this callback will save the remote couch url
          # so it can later be used by our automatic sync process
          console.log('got couchdb url from popup: ' + couchURL)
          localStorage.setItem('remoteCouch', couchURL)
          opened.close()
          sync()
 
        # open the popup
        opened = window.open(
          '/popup.html',
          '_blank',
          'height=400, width=550'
        )
    customHandlers: hg.varhash {}

  state.customHandlers.put('setDay', hg.value setDay.bind null, state)

  return state
    
vrenderMain = (state) ->
  vrenderChosen = tabs[state.activeTab or 'Input']
  if vrenderChosen == 'Input'
    vrenderChosen = Input.buildRenderer state.InputState

  activeDate = date.parseDate state.InputState.activeDay, 'yyyy-MM-dd'
  if 16 > Math.abs date.difference activeDate, new Date, 'hour'
    prettydate = 'hoje'
  prettydate = date.format(activeDate, 'dd/MM')

  (div id: 'main',
    (nav className: 'navbar navbar-default',
      (div className: 'container',
        (div className: 'navbar-header',
          (button
            className: 'btn btn-default'
            'ev-click': hg.sendClick state.channels.getRemoteCouch
          , 'SYNC')
        )
        (div {},
          (form className: 'navbar-form navbar-left',
            (div className: 'form-group', style: {display: 'inline'},
              (div className: 'input-group',
                (input
                  'ev-input': hg.sendChange state.channels.search
                  name: 'term'
                  type: 'text'
                  attributes:
                    placeholder: 'Procurar produtos'
                )
                (span className: 'input-group-addon',
                  (span className: 'glyphicon glyphicon-search')
                )
              )
            )
          )
          (ul className: 'nav navbar-right nav-pills',
            (li className: ('active' if state.activeTab == 'Input'),
              (a
                href: '#'
                value: 'Input'
                'ev-click': hg.sendClick state.channels.changeTab, 'Input'
              , 'Lançamentos de ' + prettydate)
            )
            (li className: ('active' if state.activeTab == 'Dias') or '',
              (a
                href: '#'
                value: 'Dias'
                'ev-click': hg.sendClick state.channels.showDaysList
              , 'Dias')
            )
          )
        )
      )
    )
    (div className: 'container', id: 'container',
      (vrenderChosen state)
    )
  )

vrenderSearchResults = (state) ->
  (ul id: 'search',
    (li {},
      (a
        href: '#'
        'ev-click': hg.sendClick state.channels.showItemData, r.ref
      , r.ref)
    ) for r in state.searchResults
  )

vrenderDias = (state) ->
  rows = []
  for day, j in state.daysList
    month = parseInt day.day.split('-')[1]
    monthClass = switch
      when month % 3 == 0 then 'success'
      when month % 2 == 0 then 'active'
      else ''
    rows.push (tr className: monthClass + ' ' + (if j < 15 then 'bigger' else ''),
      (td {},
        (a
          href: "##{day.day}"
          value: day.day
          'ev-click': hg.sendClick state.channels.goToDay, day.day
        , "#{day.day.split('-').reverse().join('/')}")
      )
      (td {}, "R$ #{Reais.fromInteger day.receita}")
    )

  (table id: 'dias', className: 'table table-bordered',
    (thead {},
      (tr {},
        (th {}, 'Dia')
        (th {}, 'Total vendido')
      )
    )
    (tbody {},
      rows
    )
  )

vrenderItem = (state) ->
  (div id: 'item',
    (h1 {}, Titulo state.itemData.name)
    (div {},
      (div className: 'col-md-3',
        (div className: 'display-box',
          (h3 {className: 'box-label'}, 'EM ESTOQUE')
          (h2 {className: 'box-value'}, '' + state.itemData.stock)
        ) if state.itemData.stock
      )
      (div className: 'col-md-3',
        (div className: 'display-box',
          (h3 {className: 'box-label'}, 'R$')
          (h2 {className: 'box-value'}, Reais.fromInteger state.itemData.price)
        ) if state.itemData.price
      )
      (div className: 'col-md-6',
        (table id: 'events', className: 'table table-stripped table-bordered table-hover',
          (thead {},
            (tr {},
              (th {}, 'Dia')
              (th {}, 'Q')
              (th {}, 'R$')
              (th {})
            )
          )
          (tbody {},
            (tr className: (if event.compra then 'success' else ''),
              (td {},
               (a
                 href: "##{event.id}"
                 value: event.id
                 'ev-click': hg.sendClick state.channels.goToDay, event.id
               , event.day)
              )
              (td {}, '' + event.q + ' ' + event.u)
              (td {}, Reais.fromInteger(event.p, 'R$ ') + ' por ' + event.u)
              (td {}, if event.compra then '(compra)' else '')
            ) for event in state.itemData.events
          )
        )
      )
    )
  )

state = theState()

# startup functions
initialDay = date.format(date.parseDate(location.hash.substr(1), 'yyyy-MM-dd') or new Date, 'yyyy-MM-dd')
state.customHandlers.setDay()(initialDay)

# listeners
Offline.on 'up', sync
repeat = (something) ->
  something()
  setTimeout ->
    repeat something
  , 3600000
repeat sync

tabs =
  'Input': 'Input'
  'Dias': vrenderDias
  'SearchResults': vrenderSearchResults
  'Item': vrenderItem

# run
hg.app document.body, state, vrenderMain
