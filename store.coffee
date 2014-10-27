fs      = require 'fs'
PouchDB = require 'pouchdb'

log = -> console.log arguments

class Store
  constructor: (name='vendasalva') ->
    @pouch = new PouchDB(name)
    @pouch.put JSON.parse fs.readFileSync __dirname + '/ddoc.json', encoding: 'utf-8'

  reset: ->
    @pouch.destroy()

  on: (type, listener) ->
    @changes.on(type, listener)

  get: (id) ->
    @pouch.get(id)

module.exports = new Store()
