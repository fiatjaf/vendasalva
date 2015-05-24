require 'setimmediate'

Delegator  = require('./setup').Delegator
date       = require 'date-extended'

sendClick  = require 'value-event/click'
sendSubmit = require 'value-event/submit'
sendChange = require 'value-event/change'

{div, span, pre, nav,
 small, i, p, a, button,
 h1, h2, h3, h4,
 form, legend, fieldset, input, textarea, select,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrenderMain = (state, channels) ->
  activeDate = date.parseDate state.input.activeDay, 'yyyy-MM-dd'
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
            'ev-click': sendClick channels.handleSync
          , 'SYNC')
        )
        (div {},
          (form
            'ev-submit': sendSubmit channels.search
            className: 'navbar-form navbar-left'
          ,
            (div className: 'form-group', style: {display: 'inline'},
              (div className: 'input-group',
                (input
                  'ev-input': sendChange channels.search
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
                'ev-click': sendClick channels.changeTab, 'Input'
              , 'Lançamentos de ' + prettydate)
            )
            (li className: ('active' if state.activeTab == 'Resumo') or '',
              (a
                href: '#'
                value: 'Resumo'
                'ev-click': sendClick channels.changeTab, 'Resumo'
              , 'Resumo')
            )
            (li className: ('active' if state.activeTab == 'Dias') or '',
              (a
                href: '#'
                value: 'Dias'
                'ev-click': sendClick channels.showDaysList
              , 'Dias')
            )
          )
        )
      )
    )
    (div className: 'container', id: 'container',
      (tabs[state.activeTab or 'Input'](state, channels))
    )
  )

# doing the thing
State = require './state'
handlers = require './handlers'

# startup functions
initialDay = date.format(date.parseDate(location.hash.substr(1), 'yyyy-MM-dd') or new Date, 'yyyy-MM-dd')
handlers.updateDay State, initialDay

tabs =
  'Input': require './vrender-input'
  'Dias': require './vrender-dias'
  'Resumo': require './vrender-resumo'
  'SearchResults': require './vrender-searchresults'

# turning the handlers into dom-delegator pre-binded-with-State channels
createChannel = (acc, name) ->
  acc[name] = Delegator.allocateHandle(
    handlers[name].bind(handlers, State)
  )
  return acc
channels = Object.keys(handlers).reduce createChannel, {}

# run
mainloop = (require './loop')(State.itself(), vrenderMain, channels,
  diff: require 'virtual-dom/vtree/diff'
  patch: require 'virtual-dom/vdom/patch'
  create: require 'virtual-dom/vdom/create-element'
)
document.body.appendChild mainloop.target
State.subscribe (state) -> mainloop.update state
