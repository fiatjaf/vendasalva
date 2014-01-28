define( function (require) {
  var _ = require('lodash')
  var $ = require('jquery')

  return {
    initialize: function (app) {

      // serialize form
      app.sandbox.form = function ($el) {
        var s = $el.serializeArray()
        return _.object(
          _.zip(
            _.pluck(s, 'name'), 
            _.pluck(s, 'value')
          )
        )
      }

      // templates
      _.templateSettings = {
        evaluate: /\{\%(.+?)\%\}/g,
        interpolate: /\{\$(.+?)\$\}/g,
        escape: /\{\{(.+?)\}\}/g
      }
      app.sandbox.tpl = function (tpl, data) {
        return _.template(tpl, data)
      }

      // internet
      var nointernet = []
      var yesinternet = []
      app.sandbox.onInternetUp = function (callback) {
        yesinternet.push(callback)
      }
      app.sandbox.onInternetDown = function (callback) {
        nointernet.push(callback)
      }

      var up = false
      
      function check () {
        setTimeout( function () {
          $.ajax({
            url: 'http://fiatjaf.cloudant.com',
            success: function () {
              if (up) return
              else up = true

              _.each(yesinternet, function (callback) {
                callback()
              })
            },
            error: function () {
              if (!up) return
              else up = false

              _.each(nointernet, function (callback) {
                callback()
              })
            }
          })
          check()
        }, 30000)
      }
      check()

    }
  }
})
