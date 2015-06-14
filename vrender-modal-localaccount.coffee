store = './store'

sendSubmit = require 'value-event/submit'
sendClick  = require 'value-event/click'

{div, span, pre, nav, header,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrenderModalLocalAccount = (state, channels) ->
  (div {},
    (header {},
      (h4 {}, 'Usar outra conta existente neste computador')
      (a
        href: '#'
        'ev-click': sendClick channels.closeModal
      , '×')
    )
    (form
      'ev-click': sendSubmit channels.changeLocalAccount
    ,
      (input
        type: "text"
        name: "pouchName"
        placeholder: "Nome do banco de dados local"
        value: store.pouchName
      )
      (button
        className: 'btn btn-primary'
        type: "submit"
      , "Usar")
    )
  )

module.exports = vrenderModalLocalAccount
