define ['pouchdb', 'lunr', 'promise'], (PouchDB, lunr, Promise) ->

  class Store
    constructor: ->
      @db = new PouchDB 'vendasalva'
      @fti = lunr ->
        @field 'name', {boost: 10}
        @ref '_id'
    
      # check existence of 'items' view at design doc
      @db.get '_design/main', (err, doc) =>
        mapfun = '''
                 function (doc) {
                   if (doc.type && doc.type == 'item') {
                     var edited = doc._rev.split('-');
                     emit(parseInt(edited[0]), null);
                   }
                 }
                 '''
        change = false
        if doc and not doc.views
          doc.views =
            items:
              map: mapfun
          change = true
        else if doc and doc.views
          unless doc.views.items and doc.views.items.map == mapfun
            doc.views.items =
              map: mapfun
            change = true
        else
          doc =
            _id: '_design/main'
            views:
              items:
                map: mapfun
          change = true

        if change
          @db.put doc

        # create fulltext index
        @db.query 'main/items', include_docs: true, (err, res) =>
          for row in res.rows
            @fti.add row.doc

    search: (str) ->
      return new Promise (resolve) =>
        keys = []
        for found in @fti.search str
          keys.push found.ref
        @db.allDocs include_docs: true, keys: keys, (err, res) ->
          if res
            resolve res.rows.map (row) -> row.doc

    add: (itemName) ->
      name = itemName
      return new Promise (resolve, reject) =>
        @db.post
          name: name
          type: 'item'
        , (err, res) =>
          if res
            @fti.add
              _id: res.id
              name: name
            resolve res.id
          else
            reject err
