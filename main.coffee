React     = require 'react'
Reactable = require 'Reactable'
Reais     = require 'reais'
dayParser = require('./parser/dia.js').parse
store     = require './store.coffee'

{div, span, pre, nav,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = React.DOM

Main = React.createClass
  displayName: 'Main'
  getInitialState: ->
    day: (new Date).toISOString().split('T')[0]
    Chosen: Input

  reset: (e) ->
    e.preventDefault()
    store.reset().then(-> location.reload())

  render: ->
    (div {id: 'main'},
      (nav {},
        (div className: 'menu',
          (a
            href: '#'
            onClick: @jumpTo('Input')
          , 'Lançamentos')
          (a
            href: '#'
            onClick: @jumpTo('Dias')
          , 'Dias')
        )
        (button
          onClick: @reset
        , 'RESET')
      )
      (Search {})
      (div id: 'container',
        (@state.Chosen
          day: @state.day
          onDaySelected: @jumpTo('Input')
        )
      )
    )

  jumpTo: (choice) ->
    choices =
      'Input': Input
      'Dias': Dias
    (e) =>
      e.preventDefault() if e and e.preventDefault

      state = {Chosen: choices[choice]}
      if choice == 'Input' and typeof e == 'string'
        state.day = e

      @setState state

Search = React.createClass
  displayName: 'Search'

  render: ->
    (div id: 'search')

Input = React.createClass
  displayName: 'Dashboard'

  getInitialState: ->
    facts: []

  render: ->
    vendas = []
    compras = []
    contas = []
    comments = []
    caixa = [{desc: 'Vendas', value: 0}]
    caixa.saldo = 0
    receita = 0
    for fact in @state.facts
      fact.value = parseFloat(fact.value) or 0

      switch fact.kind
        when 'venda'
          vendas.push fact
          caixa[0].value += fact.value if fact.pagamento == 'dinheiro'
          caixa.saldo += fact.value
          receita += fact.value
        when 'compra' then compras.push fact
        when 'conta'
          contas.push fact
        when 'entrada'
          caixa.push fact
          caixa.saldo += fact.value
        when 'saída'
          fact.value = -fact.value
          caixa.push fact
          caixa.saldo += fact.value
        when 'comment' then comments.push fact

    (div className: 'dashboard',
      (div className: 'half',
        (Day
          day: @props.day
          onChange: @dayChanged
        )
      )
      (div className: 'half',
        (div className: 'facts',
          (div className: 'vendas',
            (h2 {}, 'Vendas')
            (h4 {}, "Total: #{receita}")
            (Reactable.Table data: vendas)
          ) if vendas.length
          (div className: 'compras',
            (h2 {}, 'Compras')
            (ul {},
              (li {key: i},
                (h3 {}, compra.fornecedor)
                (Reactable.Table data: compra.items)
                (div {ref: j},
                  "+ #{extra.desc}: #{extra.value}"
                ) for extra, j in compra.extras if compra.extras
                (div {}, "Total: #{compra.total}") if compra.total
              ) for compra, i in compras
            )
          ) if compras.length
          (div className: 'contas',
            (h2 {}, 'Pagamentos')
            (Reactable.Table data: contas)
          ) if contas.length
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
                (tr {ref: i},
                  (td {}, row.desc)
                  (td {}, if row.value < 0 then row.value else null)
                  (td {}, if row.value > 0 then row.value else null)
                ) for row, i in caixa
              )
              (tfoot {},
                (tr {},
                  (th {colSpan: 3}, caixa.saldo)
                )
              )
            )
          )
          (div className: 'notas',
            (h2 {}, 'Anotações')
            (pre {key: i}, c.note) for c, i in comments
          ) if comments.length
        )
      )
    )

  dayChanged: (facts) ->
    @setState facts: facts

Day = React.createClass
  displayName: 'Day'

  getInitialState: ->
    raw: localStorage.getItem @props.day + ':raw'
    rev: localStorage.getItem @props.day + ':rev'
    parsed: {}
    failure: false

  componentDidMount: ->
    if @props.day
      store.get(@props.day).then (doc) =>
        return if not doc
        if not localStorage.getItem(@props.day + ':rev') or
           doc._rev > localStorage.getItem(@props.day + ':rev')
          @setState rev: doc._rev
          @parse doc.raw

  parse: (raw) ->
    try
      parsed = dayParser raw
      failure = false
      @props.onChange parsed if @props.onChange
    catch x
      console.log x
      parsed = @state.parsed
      failure = true

    @setState
      raw: raw
      parsed: parsed
      failure: failure

  render: ->
    (div className: 'day',
      (textarea
        value: @state.raw
        onChange: @handleChange
      )
      (button
        onClick: @save
      , 'Salvar')
    )

  handleChange: (e) ->
    localStorage.setItem @props.day + ':raw', e.target.value
    localStorage.setItem @props.day + ':rev', @state.rev if @state.rev
    @parse e.target.value

  save: (e) ->
    e.preventDefault() if e
    doc = {_id: @props.day, raw: @state.raw}
    if @state.rev
      doc._rev = @state.rev
    store.save(doc).then((res) =>
      @setState rev: res.rev
      localStorage.removeItem(@props.day + ':raw')
      localStorage.removeItem(@props.day + ':rev')
    )

Dias = React.createClass
  displayName: 'Dias'
  getInitialState: ->
    days: []

  componentDidMount: ->
    store.listDays().then((days) =>
      @setState days: days
    )

  render: ->
    (ul {},
      (li {ref: day},
        (a
          href: '#'
          onClick: @goToDay(day.day)
        , "#{day.day.split('-').reverse().join('/')}: #{day.receita}")
      ) for day in @state.days
    )

  goToDay: (day) -> (e) =>
    e.preventDefault()
    @props.onDaySelected day

React.renderComponent Main(), document.body

















