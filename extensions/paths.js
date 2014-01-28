define({
  initialize: function (app) {
    app.sandbox.routes = {
      '#/quarto/:n': {
        message: 'quarto.quarto',
        params: ['n']
      },
      '#/habitante/:_id': {
        message: 'quarto.habitante',
        params: ['_id']
      },
      '#/gerarboletos': {
        message: 'pasteboletos.pasteboletos',
        params: ['']
      },
      '#/stats/pagamentos': {
        message: 'stats.pagamentos',
        params: ['']
      },
      '#/stats/ocupacao': {
        message: 'stats.ocupacao',
        params: ['']
      },
      '#/stats/divida': {
        message: 'stats.divida',
        params: ['']
      },
      '#/': {
        message: 'lista.lista',
        params: ['']
      }
    }
    app.sandbox.zeroRoutes = function (listened) {
      if ($.isArray(listened)) {
        var hash = {}
        for (var i = 0; i < listened.length; i++) {
          hash[listened[i]] = true
        }
        listened = hash
      }
      
      var zR = []
      for (var r in this.routes) {
        if (!(this.routes[r].message in listened)) {
          zR.push(this.routes[r].message)
        }
      }
      return zR
    }
    app.sandbox.zero = function (listened, zero) {
      var zR = this.zeroRoutes(listened)
      for (var i = 0; i < zR.length; i++) {
        this.on(zR[i], zero)
      }
    }
  }
})
