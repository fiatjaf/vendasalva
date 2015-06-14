Reais = require 'reais'

sendClick  = require 'value-event/click'

{div, span, pre, nav,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrenderDias = (daysState, channels) ->
  rows = []
  for day, j in daysState.list
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
          'ev-click': sendClick channels.goToDay, day.day
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

module.exports = vrenderDias
