
define(['promise', 'stores/item'], function(Promise, ItemStore) {
  var Dispatcher;
  Dispatcher = (function() {

    Dispatcher.prototype._items = new ItemStore();

    function Dispatcher() {}

    Dispatcher.prototype.searchItem = function(str) {
      var _this = this;
      return new Promise(function(resolve) {
        return _this._items.search(str).then(function(ids) {
          console.log(ids);
          return resolve(ids);
        });
      });
    };

    Dispatcher.prototype.addItem = function(name) {
      var _this = this;
      return new Promise(function(resolve) {
        return _this._items.add(name).then(function(res) {
          console.log(res);
          return resolve(res);
        });
      });
    };

    return Dispatcher;

  })();
  return Dispatcher;
});
