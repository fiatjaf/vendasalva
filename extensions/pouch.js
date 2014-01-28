define(['../modules/pouchdb.js'], function (PouchDB) {
  return {
    initialize: function (app) {
      var database = 'vendasalva'
      var pouch, remote, local

      function sync () {
        if (remote && local) {
          local.replicate.from(remote, {continuous: true})
          local.replicate.to(remote, {continuous: true})
        }
      }

      function startLocal () {
        if (config.local) {
          local = PouchDB(database)
          sync()
          pouch = local
        }
      }

      function startRemote () {
        try {
          var couchurl = 'https://fiatjaf.cloudant.com/' + database
          remote = PouchDB(couchurl)
          pouch = remote
        }
        catch (e) {
          console.log('Sem internet; ou não existe, por algum motivo, o banco de dados remoto.')
        }
      }

      app.sandbox.onInternetDown( function () {
        startLocal()
      })
      app.sandbox.onInternetUp( function () {
        startRemote()
        sync()
      })

      app.sandbox.pouch = pouch
    }
  }
})
