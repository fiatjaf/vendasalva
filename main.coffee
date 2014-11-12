Reais        = require 'reais'
Titulo       = require('titulo').toLaxTitleCase
flatten      = require 'flatten'
dayParser    = require('./parser/dia.js').parse
store        = require './store.coffee'

h = (tag, props, children...) ->
  if typeof props is 'string' or typeof props is 'object' and 'tagName' of props
    children.unshift props
    props = {}
  children = flatten children or []
  Cycle.h.apply this, [tag, props, children]

vrenderMain = (props) ->
  vrenderChosen = tabs[props.chosen or 'Input']

  h '#main'
  , h 'nav'
    , h '.menu'
      , h 'a', href: '#', tabName: 'Input', 'ev-click': '^tab'
        , 'Lançamentos'
        h 'a', href: '#', tabName: 'Dias', 'ev-click': '^tab'
        , 'Dias'
      , h '^input', value: props.couchURL, 'ev-change': '^changeCouchURL'
      , h '^button', 'ev-click': '^sync'
        , 'SYNC'
    , vrenderSearch(props)
    , h '#container'
      , vrenderChosen(props)

vrenderDias = (props) ->
  h 'table#dias'
  , h 'thead'
    , h 'tr'
      , h 'th', 'Dia'
      , h 'th', 'Total vendido'
  , h 'tbody'
    , (h 'tr', key: day
      , h 'td'
        , h 'a',
          key: "##{day.day}"
          value: day.day
          'ev-click': '^selectDay'
      , h 'td', "R$ #{Reais.fromInteger day.receita}"
      ) for day in props.daysList

vrenderSearch = (props) -> h '#search'

vrenderPrices = (props) ->
  h '#prices'
  , h 'tbody'
    , (h 'tr'
      , h 'td'
        , h 'a',
          href: "##{price.id}"
          value: price.id
          'ev-click': '^selectDay'
          , price.day
      , h 'td', price.name
      , h 'td', 'R$ ' + Reais.fromInteger price.price
      , h 'td', if price.compra then '(preço de compra)' else ''
      ) for price in props.listedPrices

vrenderInput = (props) ->
  h '#dashboard'
  , h '.full'
    , h 'h1', [
      if (new Date).toISOString().split('T')[0] == props.selectedDay then 'Hoje, ' else ''
      props.selectedDay.split('-').reverse().join('/')
    ]
  , h 'half'
    , h '.day'
      , h 'textarea', value: props.raw, 'ev-change': '^inputChanged'
      , h 'button', 'ev-click': '^saveInput'
        , 'Salvar'
  , h 'half'
    , h '.facts'
      , h '.vendas'
        , h 'h2', 'Vendas'
        , h 'h3', "Total: R$ #{Reais.fromInteger receita}"
        , vrenderTable data: props.parsedData.vendas
      , h '.compras'
        , h 'h2', 'Compras'
        , h 'ul'
          , ((h 'li'
            , h 'h3', Titulo compra.fornecedor
            , vrenderTable data: compra.items
            , h 'div', "+ #{Titulo extra.desc}: R$ #{Reais.fromInteger extra.value}"
            , h 'h4', "Total: R$ #{Reais.fromInteger compra.total}"
            ) for compra in props.parsedData.compras.length)
      , h '.contas'
        , h 'h2', 'Pagamentos'
        , vrenderTable data: props.parsedData.contas
      , h '.caixa'
        , h 'h2', 'Caixa'
        , h 'table'
          , h 'thead'
            , h 'tr'
              , h 'th'
              , h 'th', 'Saídas'
              , h 'th', 'Entradas'
          , h 'tbody'
            , ((h 'tr'
              , h 'td', Titulo row.desc
              , h 'td', (if row.value < 0 then 'R$ ' + Reais.fromInteger row.value else null)
              , h 'td', (if row.value > 0 then 'R$ ' + Reais.fromInteger row.value else null)
              ) for row in props.parsedData.caixa)
          , h 'tfoot'
            , h 'tr'
              , h 'td', 'colspan': 3, 'R$ ' + Reais.fromInteger props.parsedData.caixa.saldo
      , h 'notas'
        , h 'h2', 'Anotações'
        , ((h 'pre', c.note) for c in props.parsedData.comments)

vrenderTable = (data) -> h 'table'

tabs =
  'Input': vrenderInput
  'Dias': vrenderDias
  'Prices': vrenderPrices

View = Cycle.defineView [
  'couchURL', 'daysList', 'selectedDay', 'searchOptions'
], (model) ->
  return {
    vtree$: model. vrenderMain model
    events: ['^tab', '^selectDay',
             '^changeCouchURL', '^sync',
             '^inputChanged', '^saveInput']
  }

Intent = Cycle.defineIntent [
  '^tab', '^selectDay',
  '^changeCouchURL', '^sync',
  '^inputChanged', '^saveInput',
], (view) ->
  '$goToDay': view['^selectDay'].map((ev) -> ev.target.value)
  '$setCouchURL': view['^changeCouchURL'].map((ev) -> ev.target.value)

Model = Cycle.defineModel [
  '$goToDay',
  '$setCouchURL', 'doSync$',
  '$processSearchOptions'
], (intent) ->
  intent.doSync
        .combineLatest(intent.setCouchURL, (syncEv, url) ->
          syncing = store.sync(url)
          console.log 'replication started'
          syncing.on 'change', (info) -> console.log 'change', info
          syncing.on 'error', (info) -> console.log 'error', info
          syncing.on 'complete', (info) =>
            console.log 'replication complete', info
            localStorage.setItem 'couchURL', url
        )

  @items = lunr ->
    this.use lunr.pt
    this.field 'item'
    this.ref 'item'

  store.listItems().then((items) =>
    @items.add({item: item}) for item in items
  )

  parseInput = (input) ->
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
        when 'comment' then comments.push fact

  return {
    props: Rx.Observable.merge(o for k, o of intent)
                        .startWith({
                          couchURL: localStorage.getItem 'couchURL'
                          parsedData: {}
                          daysList: []
                          selectedDay: (new Date).toISOString().split('T')[0]
                          searchOptions: []
                        })
                        .map
  }

Cycle.renderEvery View.vtree$, document.body
Cycle.link Model, View, Intent
















