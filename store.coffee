PouchDB = require 'pouchdb'
PEG     = require 'pegjs'

log = -> console.log arguments[0]

class Store
  constructor: (name='vendasalva') ->
    @pouch = new PouchDB(name)

    @changes = @pouch.changes()
    @pouch.on('error', log)

    @buildParser()
    @buildItemsIndex()

  buildParser: ->
    @parser = {parse: -> []}
    @get('_design/vendasalva').then((doc) =>
      @parser = PEG.buildParser doc.grammar
    )

  buildItemsIndex: ->
    @itemsidx = lunr ->
      this.use lunr.pt
      this.field 'item'
      this.ref 'item'
    @listItems().then((items) =>
      @itemsidx.add({item: item}) for item in items
    )

  afterSyncHook: (info) ->
    @buildParser()
    @buildItemsIndex()

  on: (type, listener) ->
    @changes.on(type, listener)

  get: (id) ->
    @pouch.get(id).catch(log)

  save: (doc) ->
    @pouch.put(doc).catch(log)

  sync: (to) ->
    syncinc = @pouch.sync(to)
    syncinc.on 'complete', (info) => @afterSyncHook info
    return syncinc

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

  grabItemData: (itemName) ->
    @pouch.query('vendasalva/main',
      startkey: ['item', itemName, {}]
      endkey: ['item', itemName, null]
      descending: true
      reduce: false
    ).catch(log).then((res) ->
      data =
        name: itemName
        events: []
        price: null
        stock: null

      stock_c = 0
      price_c =
        last_compra: 0
        proportions: []
        raw_prices: []

      for row in res.rows.reverse()
        data.events.unshift {
          id: row.id
          day: row.key[2].split('-').reverse().join('/')
          p: row.value.p
          u: row.value.u
          q: row.value.q
          compra: row.value.compra
        }

        # sum or subtract stock
        stock_c += if row.value.compra then row.value.q else -row.value.q

        # bizarrely find recommended price based on past relations V/C
        if row.value.compra
          price_c.last_compra = row.value.p
        else
          price_c.raw_prices.push row.value.p
          if price_c.last_compra isnt 0
            rel = row.value.p/price_c.last_compra
            price_c.proportions.push rel

      if stock_c >= 0
        # stock is only valid if it is greater than zero
        data.stock = stock_c

      if price_c.proportions.length > 10
        # get the last ten and apply them to the last_compra
        data.price = (rel*price_c.last_compra for rel in price_c.proportions.slice(-10)).reduce((a,b) -> a+b) / 10
      else if price_c.raw_prices.length
        data.price = price_c.raw_prices.reduce((a,b) -> a+b) / price_c.raw_prices.length

      return data
    )

  listItems: ->
    @pouch.query('vendasalva/main',
      startkey: ['item', null]
      endkey: ['item', {}]
      reduce: true
      group_level: 2
    ).catch(log).then((res) ->
      res.rows.map (row) -> row.key[1]
    )

  searchItem: (q) -> @itemsidx.search q

  parseDay: (s) -> @parser.parse s

module.exports = new Store()
