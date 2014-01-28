require.config({
  paths: {
    'lodash': 'http://cdnjs.cloudflare.com/ajax/libs/lodash.js/2.4.1/lodash.min',
    'd3': 'http://cdnjs.cloudflare.com/ajax/libs/d3/3.4.1/d3.min',
    'moment': 'http://cdnjs.cloudflare.com/ajax/libs/moment.js/2.5.1/moment.min',
    'path': 'http://cdnjs.cloudflare.com/ajax/libs/path.js/0.8.4/path.min',
    'jquery': 'http://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js',
  }
})

require(['bower_components/aura/lib/aura'], function (Aura) {
  var app = new Aura();
  app.use('extensions/utils')
  app.use('extensions/pouch')
  app.use('extensions/reais')
  app.use('extensions/pikaday')
  app.use('extensions/paths')
  app.config.mediator = {
    maxListeners: 100
  }
  app.start();
})
