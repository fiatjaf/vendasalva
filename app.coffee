curl.config
  paths:
    react: 'http://cdnjs.cloudflare.com/ajax/libs/react/0.9.0/react.js'
    lodash: 'http://cdnjs.cloudflare.com/ajax/libs/lodash.js/2.4.1/lodash.min.js',
    moment: 'http://cdnjs.cloudflare.com/ajax/libs/moment.js/2.5.1/moment.min.js',
    promise: 'lib/bluebird'
    pouchdb: 'lib/pouchdb'
    lunr: 'lib/lunr'

curl ['react', 'dispatcher', 'components/SearchItems'], (React, Dispatcher, SearchItems) ->
  dispatcher = new Dispatcher()
  React.renderComponent SearchItems(dispatcher: dispatcher), document.getElementById 'items'

