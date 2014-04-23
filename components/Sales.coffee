define ['components/DispatcherMixin', 'components/SearchItems', 'components/Reais', 'components/Number', 'components/Date', 'react'], (DispatcherMixin, React) ->
  {style, img, button, div, span, a, p, hr, label, fieldset, legend, table, tr, th, td, h1, h2, h3, h4, form, input, textarea} = React.DOM

  Sales = React.createClass
    mixins: [DispatcherMixin]
    getInitialState: ->
      sales: []

    componentDidMount: ->
      
    
    render: ->
      (Sale key: sale._id) for sale in @state.sales

  Sale = React.createClass
    mixins: [DispatcherMixin]
    getInitialState: ->
      saleData: @props.data or {}

    saveSale: (e) ->
      @dispatcher.addSale @state.saleData
      e.preventDefault()

    handleItem: (value) ->
      @setState
        saleData:
          item: value

    handleQuantity: ->
    handleNumber: ->
    handleDate: ->

    render: ->
      (div {},
        (h2 {}, 'Vendas')
        (form {},
          (SearchItems
            dispatcher: @dispatcher
            value: @state.saleData.item
            onChange: @handleItem),
          (Number
            dispatcher: @dispatcher
            value: @state.saleData.quantity
            onChange: @handleQuantity),
          (Reais
            dispatcher: @dispatcher
            value: @state.saleData.value
            onChange: @handleValue),
          (Date
            dispatcher: @dispatcher
            value: @state.saleData.date
            onChange: @handleDate),
        )
        (input type: 'text', placeholder: 'ADD', onClick: @addItem)
      )




