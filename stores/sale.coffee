define ['pouchdb', 'promise'], (PouchDB, Promise) ->

  class Store
    constructor: ->
      @db = new PouchDB 'vendasalva'

      # check existence of 'sales_per_item' and 'sales_per_day' view at design doc
      @db.get '_design/main', (err, doc) =>
        peritem_mapfun = '''
          function (doc) {
            if (doc.type && doc.type == 'sale') {
              emit([doc.item, date[0], date[1], date[2]], doc.value)
            }
          }
        '''
        perday_mapfun = '''
          function (doc) {
            if (doc.type && doc.type == 'sale') {
              var date = doc.date.split('-')
              emit([date[0], date[1], date[2]], doc.value)
            }
          }
        '''
        change = false
        if doc and not doc.views
          doc.views =
            sales_per_day:
              map: perday_mapfun
              reduce: '_sum'
            sales_per_item:
              map: peritem_mapfun
              reduce: '_sum'
          change = true
        else if doc and doc.views
          unless doc.views.sales_per_day and doc.views.sales_per_day.map == perday_mapfun
            doc.views.sales_per_day =
              map: perday_mapfun
              reduce: '_sum'
            change = true
          unless doc.views.sales_per_item and doc.views.sales_per_item.map == peritem_mapfun
            doc.views.sales_per_item =
              map: peritem_mapfun
              reduce: '_sum'
            change = true
        else if not doc
          doc =
            _id: '_design/main'
            views:
              sales_per_day:
                map: perday_mapfun
                reduce: '_sum'
              sales_per_item:
                map: peritem_mapfun
                reduce: '_sum'
          change = true

        if change
          @db.put doc

    fetchDays: (params) ->
      return new Promise (resolve, reject) =>
        callback = (err, res) =>
          if not err and res
            resolve (row.doc for row in res.rows)
          else
            reject err
        if 'range' of params
          @db.query 'main/sales_per_day',
            descending: true
            include_docs: true
            start_key: params.range[0].split('-')
            end_key: params.range[1].split('-')
          , callback
        else if 'days' of params
          @db.query 'main/sales_per_day',
            descending: true
            include_docs: true
            keys: (day.split('-') for day in params.days)
          , callback

    add: (saleDoc) ->
      @db.post saleDoc, (err, res) =>
        if not err and res
          resolve res.id
        else
          reject err

    get: (saleId) ->
      return new Promise (resolve, reject) =>
        @db.get saleId, (err, res) ->
          if not err and res
            resolve res
          else
            reject err
