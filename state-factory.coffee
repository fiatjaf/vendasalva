update = require 'immupdate'

class StateFactory
  constructor: (@state) ->
  silentlyUpdate: ->
    u = update.bind @, @state
    @state = u.apply @, arguments
  change: ->
    @silentlyUpdate.apply @, arguments
    @cb @state
  subscribe: (cb) -> @cb = cb
  itself: -> @state
  get: (prop) ->
    ret = @state
    for degree in prop.split '.'
      ret = ret[degree]
    return ret

module.exports = StateFactory
