/*!
 * Reais
 *
 * Copyright © 2013 Giovanni Torres Parra | BSD & MIT license
 */

(function (root, factory) {
  'use strict';

  if (typeof exports === 'object') {
    // CommonJS module
    module.exports = factory();
  } 
  else if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(factory);
  } 
  else {
    root.Reais = factory();
  }
}(this, function () {

  function reaisToInteger (reais) {
    reais = reais.trim()
    var signal = ''
    if (reais[0] === '-') {
      signal = '-'
      reais = reais.slice(1)
    }
    var integer = reais.replace(/(\d*)(,(\d)?(\d)?)?.*/, function (match, a, b, c, d) {
      var reais = parseInt(a || 0)
      var centavos = parseInt((c || 0) + (d || 0))
      return reais * 100 + centavos
    })
    return parseInt(signal + integer)
  }

  function reaisFromInteger (integer) {
    return ('' + (parseFloat(integer)/100).toFixed(2)).replace('.', ',')
  }

  var Reais = function (opts) {
    var jquery = window.$ || opts.jquery
    this.field = typeof opts.field === 'string' ? jquery(opts.field) : opts.field

    jquery(this.field).on('input propertychange', function () {
      if (this.value.length) {
        var x = this.value
        this.value = ''
        x = x.replace(/.*/, function (match) {
          var match = match.replace(/\D/g, '')
          return match.slice(0, match.length-2) + ',' + match.slice(match.length-2)
        })
        this.value = x
      }
    })

    this.getInteger = function () {
      return reaisToInteger(this.field.value)
    }
  }

  Reais.toInteger = reaisToInteger
  Reais.fromInteger = reaisFromInteger

  return Reais

}))
