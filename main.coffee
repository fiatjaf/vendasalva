Reais        = require 'reais'
Titulo       = require('titulo').toLaxTitleCase
Cycle        = require 'cyclejs'
flatten      = require 'flatten'
parseDay     = require('./parser/dia.js').parse
store        = require './store.coffee'

Rx = Cycle.Rx
orhs =
  tags: ->
    callers = {}
    for tagName in arguments
      callers[tagName] = this.tag tagName
    callers
  tag: (tagName) ->
    (properties, children...) ->
      if typeof properties is 'string' or typeof properties is 'object' and 'tagName' of properties
        children.unshift properties
        properties = {}
      children = flatten(children or []).filter((x) -> x)
      Cycle.h.apply this, [tagName, properties, children]

{div, span, pre, nav,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = orhs.tags 'div', 'span', 'pre', 'nav',
 'small', 'i', 'p', 'a', 'button',
 'h1', 'h2', 'h3', 'h4',
 'form', 'legend', 'fieldset', 'input', 'textarea', 'select',
 'table', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td'
 'ul', 'li'

vrenderMain = (props) ->
  vrenderChosen = tabs[props.activeTab or 'Input']

  (div id: 'main',
    (nav {},
      (div className: 'menu',
        (a
          href: '#'
          value: 'Input'
          'ev-click': '^tab'
        , 'Lançamentos')
        (a
          href: '#'
          value: 'Dias'
          'ev-click': '^tab'
        , 'Dias')
      )
      (input
        'ev-input': '^changeCouchURL'
        type: 'text'
        value: Cycle.vdomPropHook (elem) ->
          elem.value = props.couchURL
      )
      (button
        'ev-click': '^sync'
      , 'SYNC')
    )
    (vrenderSearch props)
    (div id: 'container',
      (vrenderChosen props)
    )
  )

vrenderSearch = (props) -> (div id: '#search')

vrenderDias = (props) ->
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
            'ev-click': '^selectDay'
          , "#{day.day.split('-').reverse().join('/')}")
        )
        (td {}, "R$ #{Reais.fromInteger day.receita}")
      ) for day in props.dayList
    )
  )

vrenderItem = (props) ->
  (div id: 'item',
    (h1 {}, Titulo props.itemData.name)
    (div {},
      (div className: 'half',
        (h2 {}, '' + props.itemData.stock) if props.itemData.stock
      )
      (div className: 'half',
        (h2 {}, 'R$ ' + Reais.fromInteger props.itemData.price) if props.itemData.price
      )
    )
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
             'ev-click': '^selectDay'
           , event.day)
          )
          (td {}, '' + event.q + ' ' + event.u)
          (td {}, 'R$ ' + Reais.fromInteger event.p + ' por ' + event.u)
          (td {}, if event.compra then '(preço de compra)' else '')
        ) for event in props.itemData.events
      )
    )
  )

vrenderInput = (props) ->
  (div className: 'dashboard',
    (div className: 'full',
      (h1 {},
        if (new Date).toISOString().split('T')[0] == props.activeDay then 'Hoje, ' else ''
        props.activeDay.split('-').reverse().join('/')
      )
    )
    (div className: 'half',
      (div className: 'day',
        (textarea
          'ev-input': '^inputChanged'
        , props.rawInput)
        (button
          'ev-click': '^saveInput'
        , 'Salvar')
      )
    )
    (div className: 'half',
      (div className: 'facts',
        (div className: 'vendas',
          (h2 {}, 'Vendas')
          (h3 {}, "Total: R$ #{Reais.fromInteger props.parsedData.receita}")
          (vrenderTable
            data: props.parsedData.vendas
            columns: ['Quant','Produto','Valor pago','Forma de pagamento']
          )
        ) if props.parsedData.vendas.length
        (div className: 'compras',
          (h2 {}, 'Compras')
          (ul {},
            (li {},
              (h3 {}, Titulo compra.fornecedor)
              (vrenderTable
                data: compra.items
                columns: ['Quant', 'Produto', 'Preço total', 'Preço unitário']
              )
              (div {},
                "+ #{Titulo extra.desc}: R$ #{Reais.fromInteger extra.value}"
              ) for extra in compra.extras if compra.extras
              (h4 {}, "Total: R$ #{Reais.fromInteger compra.total}") if compra.total
            ) for compra in props.parsedData.compras
          )
        ) if props.parsedData.compras.length
        (div className: 'contas',
          (h2 {}, 'Pagamentos')
          (vrenderTable
            data: props.parsedData.contas
            columns: ['Conta', 'Valor']
            sortable: true
          )
        ) if props.parsedData.contas.length
        (div className: 'caixa',
          (h2 {}, 'Caixa')
          (table {},
            (thead {},
              (tr {},
                (th {})
                (th {}, 'Saídas')
                (th {}, 'Entradas')
              )
            )
            (tbody {},
              (tr {},
                (td {}, Titulo row.desc)
                (td {}, if row.value < 0 then 'R$ ' + Reais.fromInteger row.value else null)
                (td {}, if row.value > 0 then 'R$ ' + Reais.fromInteger row.value else null)
              ) for row in props.parsedData.caixa
            ) if props.parsedData.caixa
            (tfoot {},
              (tr {},
                (th {colspan: 3}, 'R$ ' + Reais.fromInteger props.parsedData.caixa.saldo)
              )
            )
          )
        )
        (div className: 'notas',
          (h2 {}, 'Anotações')
          (pre {key: i}, c.note) for c, i in props.parsedData.comments
        ) if props.parsedData.comments.length
      )
    )
  )

vrenderTable = (tableDefinition) ->
  {data, columns} = tableDefinition

  (table {},
    (thead {},
      (tr {},
        (th {},
          col
        ) for col in columns
      )
    )
    (tbody {},
      (tr {},
        (td {},
          "#{row[col]}" or ''
        ) for col in columns
      ) for row in data
    )
  )

tabs =
  'Input': vrenderInput
  'Dias': vrenderDias
  'Item': vrenderItem

View = Cycle.defineView ['@props'], (model) ->
  return {
    vtree$: model['@props'].map vrenderMain
    events: ['^tab', '^selectDay',
             '^changeCouchURL', '^sync',
             '^searchBoxChanged',
             '^inputChanged', '^saveInput']
  }

Intent = Cycle.defineIntent [
  '^tab', '^selectDay',
  '^changeCouchURL', '^sync',
  '^inputChanged', '^saveInput',
  '^searchBoxChanged',
  '^itemClicked'
], (view) ->
  'changeTab$': view['^tab'].map((e) ->
    e.preventDefault()
    e.target.value
   )
  'goToDay$': view['^selectDay'].map((e) ->
    e.preventDefault()
    e.target.value
  )
  'doSync$': view['^sync'].map((e) -> e.preventDefault())
  'setCouchURL$': view['^changeCouchURL'].throttle(500).map((e) -> e.target.value)
  'setInputText$': view['^inputChanged'].throttle(500).map((e) -> e.target.value)
  'saveInputText$': view['^saveInput'].map((e) ->
    e.preventDefault()
    e.target.value
  ).distinctUntilChanged()
  'showItemData$': view['^itemClicked'].map((e) ->
    e.preventDefault()
    e.target.innerText
  )
  'search$': view['^searchBoxChanged'].map((e) -> e.target.value)

Model = Cycle.defineModel [
  'changeTab$', 'goToDay$',
  'setCouchURL$', 'doSync$',
  'search$'
  'setInputText$', 'saveInputText$',
  'showItemData$'
], (intent) ->
  mods = []

  # . search
  itemsidx = lunr ->
    this.use lunr.pt
    this.field 'item'
    this.ref 'item'
  store.listItems().then((items) ->
    itemsidx.add({item: item}) for item in items
  )
  mods.push intent['search$'].map (term) -> (props) ->
    props.searchResults = itemsidx.search term
    props

  # . async initial dayList
  mods.push Rx.Observable.fromPromise(store.listDays()).map (dayList) -> (props) ->
    props.dayList = dayList
    props

  # . go to day
  mods.push intent['goToDay$'].flatMap((day) ->
    Rx.Observable.fromPromise(store.get(day)).map((doc) ->
      if not doc then [day, ''] else [day, doc.raw]
    )
  ).map (res) ->
    intent['setInputText$'].onNext(res[1])

    (props) ->
      props.activeDay = res[0]
      props.activeTab = 'Input'
      props

  # . go to item - get the prices and estoque for some item
  mods.push intent['showItemData$'].flatMap(
    (item) -> Rx.Observable.fromPromise(store.grabItemData(item))
  ).map (itemData) ->
    (props) ->
      props.activeTab = 'Item'
      props.itemData = itemData
      props

  # . go to tab
  mods.push intent['changeTab$'].map (tabName) -> (props) ->
    props.activeTab = tabName
    props

  # . set couch URL
  mods.push intent['setCouchURL$'].map (newURL) -> (props) ->
    props.couchURL = newURL
    props

  # . sync
  mods.push intent['doSync$'].map -> (props) ->
    syncing = store.sync(props.couchURL)
    console.log 'replication started'
    syncing.on 'change', (info) -> console.log 'change', info
    syncing.on 'error', (info) -> console.log 'error', info
    syncing.on 'complete', (info) =>
      console.log 'replication complete', info
      localStorage.setItem 'couchURL', props.couchURL

  # . when the input text changes, parse it
  mods.push intent['setInputText$'].map (input) -> (props) ->
    props.rawInput = input
    try
      facts = parseDay input
    catch e
      return props

    vendas = []
    compras = []
    contas = []
    comments = []
    caixa = [{desc: 'Vendas', value: 0}]
    caixa.saldo = 0
    receita = 0
    for fact in facts
      fact.value = parseFloat(fact.value) or 0

      switch fact.kind
        when 'venda'
          vendas.push {
            'Quant': fact.q
            'Produto': "#{Titulo fact.item} (#{fact.u})"
            'Valor pago': 'R$ ' + Reais.fromInteger fact.value
            'Forma de pagamento': fact.pagamento + if fact.x then " (#{fact.x}x)" else ''
          }
          caixa[0].value += fact.value if fact.pagamento == 'dinheiro'
          caixa.saldo += fact.value
          receita += fact.value
        when 'compra'
          compra = fact
          comprados = compra.items or []
          compra.items = []
          for item in comprados
            compra.items.push {
              'Quant': item.q
              'Produto': "#{Titulo item.item} (#{item.u})"
              'Preço total': 'R$ ' + Reais.fromInteger item.value
              'Preço unitário': 'R$ ' + Reais.fromInteger item.value/item.q
            }
          compras.push compra
        when 'conta'
          contas.push {
            'Conta': fact.desc
            'Valor': 'R$ ' + Reais.fromInteger fact.value
          }
        when 'entrada'
          caixa.push fact
          caixa.saldo += fact.value
        when 'saída'
          fact.value = -fact.value
          caixa.push fact
          caixa.saldo += fact.value
        when 'saida/conta'
          fact.value = -fact.value
          caixa.push fact
          caixa.saldo += fact.value
          contas.push {
            'Conta': fact.desc
            'Valor': 'R$ ' + Reais.fromInteger fact.value
          }
        when 'comment' then comments.push fact

    props.parsedData =
      vendas: vendas
      compras: compras
      contas: contas
      comments: comments
      caixa: caixa
      receita: receita
    props

  # . save the input for the day
  mods.push intent['saveInputText$'].map -> (props) ->
    store.get(props.activeDay).then((doc) ->
      doc.raw = props.rawInput
      store.save doc
    )

  return {
    '@props': Rx.Observable.merge(mods)
                           .startWith({
                             couchURL: localStorage.getItem('couchURL') or ''
                             rawInput: ''
                             parsedData:
                               vendas: []
                               compras: []
                               contas: []
                               comments: []
                               caixa: [{desc: 'Vendas', value: 0}]
                               receita: 0
                             dayList: []
                             activeDay: (new Date).toISOString().split('T')[0]
                             activeTab: 'Input'
                             searchOptions: []
                             itemData: {}
                           }).scan((props, modification) ->
                             return modification(props)
                           )
  }

Cycle.renderEvery View.vtree$, '#body'
Intent.inject View
View.inject Model
Model.inject Intent
