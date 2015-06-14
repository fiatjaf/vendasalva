sendSubmit = require 'value-event/submit'
sendClick  = require 'value-event/click'

{div, span, pre, nav, header,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrenderModalAuth = (state, channels) ->
  (div {},
    (header {},
      (h4 {}, 'Login')
      (a
        href: '#'
        'ev-click': sendClick channels.closeModal
      , '×')
    )
    (form
      'ev-click': sendSubmit channels.login
    ,
      (input
        type: "text"
        name: "name"
      )
      (input
        name: "password"
        type: "password"
      )
      (button
        className: 'btn btn-primary'
        type: "submit"
      , "Entrar")
    )
  )

module.exports = vrenderModalAuth
