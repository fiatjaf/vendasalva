require 'setimmediate'

hg               = require 'mercury'
Promise          = require 'lie'
Reais            = require 'reais'
Titulo           = require('titulo').toLaxTitleCase
date             = require 'date-extended'

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
setDay = (state, day) ->
  state.InputState.customHandlers.updateDay()(day)
  state.activeTab.set 'Input'

sync = (force=false) ->
  lastSync = localStorage.getItem 'lastSync'
  if force or not lastSync or parseInt(lastSync) + 3600 < parseInt(Date.now()/1000)
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

getRemoteCouch = ->
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
    forcedSearchValue: hg.value ''

    InputState: Input()

    channels:
      changeTab: (state, data) -> state.activeTab.set data # data is the tabname itself
      showDaysList: (state, data) ->
        store.listDays().then((daysList) ->
          state.daysList.set daysList
          state.activeTab.set 'Dias'
        )
      goToDay: (state, data) -> setDay state, data # data is the day itself, as a string
      search: (state, data) ->
        state.forcedSearchValue.set ''
        results = store.searchItem data.term
        if results.length
          if results.length < 7
            Promise.all((store.grabItemData i.ref for i in results)).then((items) ->
              state.searchResults.set items
              state.activeTab.set 'SearchResults'
            )
          else
            state.searchResults.set results
            state.activeTab.set 'SearchResults'
      forceSearch: (state, data) -> state.forcedSearchValue.set data
      handleSync: ->
        if localStorage.getItem 'remoteCouch' then sync(true) else getRemoteCouch()

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

  class ClickToSearchHook
    constructor: (@value) ->
    hook: (elem, propName) ->
      if @value
        setImmediate =>
          elem.value = @value
          inputEvent = new Event 'input'
          elem.dispatchEvent inputEvent

  (div id: 'main',
    (nav className: 'navbar navbar-default',
      (div className: 'container',
        (div className: 'navbar-header',
          (button
            className: 'btn btn-default'
            'ev-click': hg.sendClick state.channels.handleSync
          , 'SYNC')
        )
        (div {},
          (form
            'ev-submit': hg.sendSubmit state.channels.search
            className: 'navbar-form navbar-left'
          ,
            (div className: 'form-group', style: {display: 'inline'},
              (div className: 'input-group',
                (input
                  'ev-input': hg.sendChange state.channels.search
                  name: 'term'
                  type: 'text'
                  value: new ClickToSearchHook state.forcedSearchValue
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
            (li className: ('active' if state.activeTab == 'Resumo') or '',
              (a
                href: '#'
                value: 'Resumo'
                'ev-click': hg.sendClick state.channels.changeTab, 'Resumo'
              , 'Resumo')
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
        'ev-click': hg.sendClick state.channels.forceSearch, r.ref
      , r.ref)
    ) for r in state.searchResults if state.searchResults.length >= 7
    (vrenderItem state, item) for item in state.searchResults if state.searchResults.length < 7
  )

vrenderItem = (state, itemData) ->
  (div className: 'item',
    #(div {},
    #  (div className: 'col-md-3',
    #    (div className: 'display-box',
    #      (h3 {className: 'box-label'}, 'EM ESTOQUE')
    #      (h2 {className: 'box-value'}, '' + itemData.stock)
    #    ) if itemData.stock
    #  )
    #  (div className: 'col-md-3',
    #    (div className: 'display-box',
    #      (h3 {className: 'box-label'}, 'R$')
    #      (h2 {className: 'box-value'}, Reais.fromInteger itemData.price)
    #    ) if itemData.price
    #  )
    #)
    (h1 className: 'col-md-4', Titulo itemData.name)
    (div className: 'col-md-8',
      (table className: 'events table table-stripped table-bordered table-hover',
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
          ) for event in itemData.events
        )
      )
    )
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

state = theState()

# startup functions
initialDay = date.format(date.parseDate(location.hash.substr(1), 'yyyy-MM-dd') or new Date, 'yyyy-MM-dd')
state.customHandlers.setDay()(initialDay)

tabs =
  'Input': 'Input'
  'Dias': vrenderDias
  'Resumo': require './vrender-resumo.coffee'
  'SearchResults': vrenderSearchResults

# run
hg.app document.body, state, vrenderMain
