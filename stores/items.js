
define(['pouchdb', 'fullproof'], function(PouchDB, FullProof) {
  var db, fti;
  db = new PouchDB('vendasalva');
  fti = new FullProof.BooleanEngine();
  db.get('_design/main').then(function(doc) {
    var mapfun;
    mapfun = 'function (doc) {\n  if (doc.type and doc.type == \'item\') {\n    var edited = doc._rev.split(\'-\');\n    emit(parseInt(edited[0]), {\n      name: doc.name;\n    });\n  }\n}';
    if (!doc) {
      return db.put({
        _id: '_design/main',
        views: {
          items: {
            map: mapfun
          }
        }
      });
    } else if (doc) {
      if (doc.views && doc.views.items && doc.views.items.map === mapfun) {
        return true;
      } else {
        doc.views = {
          items: {
            map: mapfun
          }
        };
        return db.put(doc).then(function(res) {
          if (res.ok) return true;
        });
      }
    }
  }).then(function() {
    var engineReady, ftiName, index1, index2;
    ftiName = 'items';
    ({
      ftiInitializer: function(injector, callback) {
        return db.query('main/items').then(function(res) {
          var row, synchro, _i, _len, _ref, _results;
          synchro = FullProof.make_synchro_point(callback, res.rows.length);
          _ref = res.rows;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            row = _ref[_i];
            _results.push(injector.inject(row.value.nome, row.id, synchro));
          }
          return _results;
        });
      }
    });
    index1 = {
      name: 'normalIndex',
      analyzer: new FullProof.StandardAnalyzer(fullproof.normalizer.to_lowercase_nomark, fullproof.normalizer.remove_duplicate_letters),
      capabilities: new FullProof.Capabilities().setUseScores(false).setDbName(ftiName),
      initializer: ftiInitializer
    };
    index2 = {
      name: 'stemmedIndex',
      analyzer: new FullProof.StandardAnalyzer(fullproof.normalizer.to_lowercase_nomark, fullproof.english.metaphone),
      capabilities: new fullproof.Capabilities().setUseScores(false).setDbName(ftiName),
      initializer: ftiInitializer
    };
    engineReady = function(ok) {
      if (ok) {
        this.fti = true;
        return console.log('opened');
      } else {
        this.fti = false;
        return console.log('not opened');
      }
    };
    return fti.open([index1, index2], FullProof.make_callback(engineReady, true), FullProof.make_callback(engineReady, false));
  });
  return {
    search: function(str) {
      return new Promise(function(resolve, reject) {
        return fti.lookup(str, function(resultset) {
          console.log(resultset);
          if (resultset && resultset.getSize()) return resolve(resultset);
        });
      });
    },
    add: function(name) {
      return db.post({
        name: name,
        type: 'item'
      });
    }
  };
});
