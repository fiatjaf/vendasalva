define( function (require) {
  var Path = require('path')

  return {
    initialize: function () {
      var self = this

      for (var path in self.sandbox.routes) {
        var routeData = self.sandbox.routes[path]
        for (var i = 0; i < routeData.params.length; i++) {

          // listen to route changes and fire the appropriate messages
          var param = routeData.params[i] || ''
          Path.map(path).to( (function () {
            var thisRoute = path
            var argname = routeData.params[i]
            var message = routeData.message
            return function () {
              var arg = this.params[argname]
              console.log('spotted path', thisRoute, 'with argument', arg)
              console.log('firing message', message, 'with argument', arg)
              self.sandbox.emit(message, arg)
            }
          })())

          // listen to messages and set the appropriate routes
          var message = routeData.message
          var params = routeData.params
          self.sandbox.on(message, (function () {
            var thisMessage = message
            var theseParams = params
            var thisRoute = path
            return function (/* arguments */) {
              var completeRoute = thisRoute
              for (var i = 0; i < theseParams.length; i++) {
                completeRoute = completeRoute.replace(':' + theseParams[i], arguments[i])
              }
              console.log('listened message', thisMessage, 'with args', arguments)
              console.log('setting route:', completeRoute)
              if (completeRoute === location.hash) {
                console.log('already in this route. ending.')
                return false
              }
              else {
                location.hash = completeRoute
              }
            }
          })())
        }
      }
      Path.root('#/')
      Path.listen()
    }
  }
})
