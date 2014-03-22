
define(['pouchdb', 'lunr', 'promise'], function(PouchDB, lunr, Promise) {
  var Store;
  return Store = (function() {

    function Store() {
      var _this = this;
      this.db = new PouchDB('vendasalva');
      this.fti = lunr(function() {
        this.field('name', {
          boost: 10
        });
        return this.ref('_id');
      });
      this.db.get('_design/main', function(err, doc) {
        var change, mapfun;
        mapfun = 'function (doc) {\n  if (doc.type && doc.type == \'item\') {\n    var edited = doc._rev.split(\'-\');\n    emit(parseInt(edited[0]), null);\n  }\n}';
        change = false;
        if (doc && !doc.views) {
          doc.views = {
            items: {
              map: mapfun
            }
          };
          change = true;
        } else if (doc && doc.views) {
          if (!(doc.views.items && doc.views.items.map === mapfun)) {
            doc.views.items = {
              map: mapfun
            };
            change = true;
          }
        } else {
          doc = {
            _id: '_design/main',
            views: {
              items: {
                map: mapfun
              }
            }
          };
          change = true;
        }
        if (change) _this.db.put(doc);
        return _this.db.query('main/items', {
          include_docs: true
        }, function(err, res) {
          var row, _i, _len, _ref, _results;
          _ref = res.rows;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            row = _ref[_i];
            _results.push(_this.fti.add(row.doc));
          }
          return _results;
        });
      });
    }

    Store.prototype.search = function(str) {
      var _this = this;
      return new Promise(function(resolve) {
        var found, keys, _i, _len, _ref;
        keys = [];
        _ref = _this.fti.search(str);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          found = _ref[_i];
          keys.push(found.ref);
        }
        return _this.db.allDocs({
          include_docs: true,
          keys: keys
        }, function(err, res) {
          if (res) {
            return resolve(res.rows.map(function(row) {
              return row.doc;
            }));
          }
        });
      });
    };

    Store.prototype.add = function(itemName) {
      var name,
        _this = this;
      name = itemName;
      return new Promise(function(resolve, reject) {
        return _this.db.post({
          name: name,
          type: 'item'
        }, function(err, res) {
          if (res) {
            _this.fti.add({
              _id: res.id,
              name: name
            });
            return resolve(res.id);
          } else {
            return reject(err);
          }
        });
      });
    };

    return Store;

  })();
});
