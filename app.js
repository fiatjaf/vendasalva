
curl.config({
  paths: {
    react: 'http://cdnjs.cloudflare.com/ajax/libs/react/0.9.0/react.js',
    lodash: 'http://cdnjs.cloudflare.com/ajax/libs/lodash.js/2.4.1/lodash.min.js',
    moment: 'http://cdnjs.cloudflare.com/ajax/libs/moment.js/2.5.1/moment.min.js',
    promise: 'lib/promiscuous',
    pouchdb: 'lib/pouchdb',
    fullproof: 'lib/fullproof'
  }
});

curl(['react', 'dispatcher', 'components/Precos'], function(React, Dispatcher, Precos) {
  var dispatcher;
  dispatcher = new Dispatcher();
  return React.renderComponent(Precos({
    dispatcher: dispatcher
  }, document.getElementById('precos')));
});
