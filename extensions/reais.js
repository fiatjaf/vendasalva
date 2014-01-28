define(['../modules/reais.js'], function (Reais) {
  return {
    initialize: function (app) {
      app.sandbox.Reais = Reais 
      app.sandbox.fieldReais = function (field) {
        return new Reais({field: field})
      }
    }
  }
})
