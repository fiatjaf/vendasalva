Reais = require 'reais'

vrenderTable = require './vrender-table'

{div,
 h2, h3} = require 'virtual-elements'

class Chart
  constructor: ->
    @type = 'Widget'

module.exports = (resumoState, channels) ->
  (div {},
    (div className: 'col-md-6',
      (h3 {}, "Semana #{i}")
      (vrenderTable
        style: null
        data: week
        columns: ['Produto', 'Vendas']
      ) for week, i in resumoState.top.weeks
    )
    (div className: 'col-md-6',
      (h2 {}, 'Produtos com maior volume de vendas desde sempre')
      (vrenderTable
        style: null
        data: ({
          'Produto': row[0]
          'Vendas': Reais.fromInteger row[1]
        } for row in resumoState.top.overall)
        columns: ['#', 'Produto', 'Vendas']
      )
    )
  )
