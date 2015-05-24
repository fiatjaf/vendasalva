extend    = require 'xtend'
BaseEvent = require 'value-event/base-event'

module.exports = BaseEvent (ev, broadcast) ->
  detail = ev._rawEvent.detail
  data = extend detail, this.data

  broadcast data
