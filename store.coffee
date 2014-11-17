fs      = require 'fs'
PouchDB = require 'pouchdb'

log = -> console.log arguments

class Store
  constructor: (name='vendasalva') ->
    @pouch = new PouchDB(name)

    ddoc = JSON.parse fs.readFileSync __dirname + '/ddoc.json', encoding: 'utf-8'
    @pouch.get(ddoc._id).then((doc) =>
      if doc and doc._rev
        _rev = doc._rev

        # check for update num and update if it matches
        # or is not being used
        if ddoc.update and ddoc.update == doc.update
          return

      ddoc._rev = _rev
      @pouch.put(ddoc)
    ).catch(=>
      @pouch.put(ddoc)
    )

    @changes = @pouch.changes()

    @pouch.on('error', log)

  reset: ->
    @pouch.destroy()

  on: (type, listener) ->
    @changes.on(type, listener)

  get: (id) ->
    @pouch.get(id).catch(log)

  save: (doc) ->
    @pouch.put(doc).catch(log)

  sync: (to) ->
    @pouch.sync(to)

  listDays: ->
    @pouch.query('vendasalva/main',
      startkey: ['receita', null]
      endkey: ['receita', {}]
      reduce: false
    ).catch(log).then((res) ->
      makeDayFromKey = (key) ->
        (new Date key[1], key[2]-1, key[4]).toISOString().split('T')[0]

      # add first day that appears in the database
      first = res.rows[0]
      days = [{
        day: makeDayFromKey first.key
        receita: first.value
      }]

      # add all days after that, appear they or not in the database
      pos = 1
      loop

        refDay = new Date Date.parse days.slice(-1)[0].day
        refDay.setDate refDay.getDate() + 1
        refDay = refDay.toISOString().split('T')[0]

        if res.rows[pos] and makeDayFromKey(res.rows[pos].key) == refDay
          days.push {
            day: makeDayFromKey res.rows[pos].key
            receita: res.rows[pos].value
          }
          pos += 1
        else
          days.push {day: refDay, receita: 0}

        break if pos >= res.rows.length and (new Date).toISOString().split('T')[0] <= refDay

      # add 5 days before that first one
      for prev in [1..5]
        prevDay = new Date Date.parse days[0].day
        prevDay.setDate prevDay.getDate() - 1
        days.unshift {
          day: prevDay.toISOString().split('T')[0]
          receita: 0
        }

      return days.reverse()
    )

  listPrices: (itemName) ->
    @pouch.query('vendasalva/main',
      startkey: ['price', itemName, {}]
      endkey: ['price', itemName, null]
      descending: true
      reduce: false
    ).catch(log).then((res) ->
      res.rows.map (row) ->
        {
          id: row.id
          day: row.key[2].split('-').reverse().join('/')
          item: row.key[1]
          price: "#{row.value.value} por #{row.value.u}"
          compra: row.value.compra
        }
    )

  listItems: ->
    @pouch.query('vendasalva/main',
      startkey: ['price', null]
      endkey: ['price', {}]
      reduce: true
      group_level: 2
    ).catch(log).then((res) ->
      res.rows.map (row) -> row.key[1]
    )

module.exports = new Store()
