React     = require 'react'
Reactable = require 'Reactable'
dayParser = require('./parser/day-parser').parse
store     = require './store.coffee'

{div, span, pre,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select
 ul, li} = React.DOM

Main = React.createClass
  displayName: 'Main'
  reset: (e) ->
    e.preventDefault()
    store.reset().then(-> location.reload())
  render: ->
    (div {id: 'main'},
      (button
        onClick: @reset
      , 'RESET')
      (Dashboard {})
    )

Dashboard = React.createClass
  displayName: 'Dashboard'

  getInitialState: ->
    venda: []
    compra: []
    despesa: []
    caixa: []
    nota: []

  render: ->
    (div className: 'dashboard',
      (div className: 'two-third',
        (Day
          day: (new Date).toISOString().split('T')[0]
          onChange: @dayChanged
        )
      )
      (div className: 'third',
        (div className: 'facts',
          (div className: 'vendas',
            (h2 {}, 'Vendas')
            (Reactable.Table data: @state.venda)
          ) if @state.venda.length
          (div className: 'compras',
            (h2 {}, 'Compras')
            (Reactable.Table data: @state.compra)
          ) if @state.compra.length
          (div className: 'despesas',
            (h2 {}, 'Despesas soltas')
            (Reactable.Table data: @state.despesa)
          ) if @state.despesa.length
          (div className: 'caixa',
            (h2 {}, 'Movimentações de caixa')
            (Reactable.Table data: @state.caixa)
          ) if @state.caixa.length
          (div className: 'notas',
            (h2 {}, 'Anotações')
            (pre {key: Math.random()}, nota) for nota in @state.nota
          ) if @state.nota.length
        )
      )
    )

  dayChanged: (facts) ->
    blankState =
      venda: []
      compra: []
      despesa: []
      caixa: []
      nota: []
    for fact in facts
      blankState[fact.kind].push fact
    @setState blankState

Day = React.createClass
  displayName: 'Day'

  getInitialState: ->
    raw: ''
    parsed: {}
    failure: false

  componentDidMount: ->
    if @props.day
      store.get('day:' + @props.day).then (doc) =>
        @setState raw: doc.raw

  render: ->
    (div className: 'day',
      (textarea
        value: @state.raw
        onChange: @handleChange
      )
    )

  handleChange: (e) ->
    try
      parsed = dayParser e.target.value
      failure = false
      @props.onChange parsed if @props.onChange
    catch x
      parsed = @state.parsed
      failure = true

    @setState
      raw: e.target.value
      parsed: parsed
      failure: failure

React.renderComponent Main(), document.body

















