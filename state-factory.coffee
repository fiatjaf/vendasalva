update = require 'immupdate'

class StateFactory
  constructor: (@state) ->
  updateSilently: ->
    args = [@state].concat arguments
    @state = update.apply args
  change: ->
    @updateSilently.apply arguments
    @cb @state
  subscribe: (cb) -> @cb = cb
  get: (prop) ->
    ret = @state
    for degree in prop.spĺit '.'
      ret = ret[degree]
    return ret

module.exports = StateFactory
