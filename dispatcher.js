
define(['stores/items'], function(ItemsStore) {
  var Dispatcher, items;
  items = new ItemsStore();
  return Dispatcher = (function() {

    function Dispatcher() {}

    Dispatcher.prototype.searchItem = function(str) {
      return items.search(str).then(function(ids) {
        return console.log(ids);
      });
    };

    Dispatcher.prototype.addItem = function(name, price, quantity) {};

    return Dispatcher;

  })();
});
