define( function (require) {

  return {
    initialize: function () {
      var tpl = this.sandbox.tpl(require('text!./template.tpl'))
      this.html(tpl())
    }
  }
})
