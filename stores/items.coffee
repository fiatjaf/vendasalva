define ['pouchdb', 'fullproof'], (PouchDB, FullProof) ->
  db = new PouchDB 'vendasalva'
  fti = new FullProof.BooleanEngine()

  # check existence of 'items' view at design doc
  db.get('_design/main').then( (doc) ->
    mapfun = '''
             function (doc) {
               if (doc.type and doc.type == 'item') {
                 var edited = doc._rev.split('-');
                 emit(parseInt(edited[0]), {
                   name: doc.name;
                 });
               }
             }
             '''
    if not doc
      db.put
        _id: '_design/main'
        views:
          items:
            map: mapfun
    else if doc
      if doc.views and doc.views.items and doc.views.items.map == mapfun
        return true
      else
        doc.views =
          items:
            map: mapfun
        return db.put(doc).then (res) ->
          if res.ok
            return true
  ).then( ->
    # create fulltext index

    ftiName = 'items'
    ftiInitializer: (injector, callback) ->
      db.query('main/items').then (res) ->
        synchro = FullProof.make_synchro_point callback, res.rows.length
        for row in res.rows
          injector.inject row.value.nome, row.id, synchro

    index1 =
      name: 'normalIndex'
      analyzer: new FullProof.StandardAnalyzer(
        fullproof.normalizer.to_lowercase_nomark,
        fullproof.normalizer.remove_duplicate_letters)
      capabilities: new FullProof.Capabilities().setUseScores(false).setDbName(ftiName)
      initializer: ftiInitializer

    index2 =
      name: 'stemmedIndex'
      analyzer: new FullProof.StandardAnalyzer(
        fullproof.normalizer.to_lowercase_nomark,
        fullproof.english.metaphone)
      capabilities: new fullproof.Capabilities().setUseScores(false).setDbName(ftiName)
      initializer: ftiInitializer

    engineReady = (ok) ->
      if ok
        @fti = true
        console.log 'opened'
      else
        @fti = false
        console.log 'not opened'

    fti.open(
      [index1, index2],
      FullProof.make_callback(engineReady, true),
      FullProof.make_callback(engineReady, false)
    )
  )

  return {
    search: (str) ->
      return new Promise (resolve, reject) ->
        fti.lookup str, (resultset) ->
          console.log resultset
          if resultset and resultset.getSize()
            resolve resultset
    add: (name) ->
      db.post
        name: name
        type: 'item'
  }
