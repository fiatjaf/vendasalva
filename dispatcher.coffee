define ['promise', 'stores/item', 'stores/sales'], (Promise, ItemStore, SaleStore) ->
  class Dispatcher
    _items: new ItemStore()
    _sales: new SalesStore()

    constructor: ->

    searchItem: (str) ->
      return new Promise (resolve) =>
        @_items.search(str).then (ids) ->
          console.log ids
          resolve ids

    addItem: (name) ->
      return new Promise (resolve) =>
        @_items.add(name).then (id) ->
          console.log 'saved item with id ' + id
          resolve id

    addSale: (data) ->
      return new Promise (resolve) =>
        doc =
          item: data.item
          quantity: data.quantity
          value: data.value
          date: data.date
        if not data.value
          @_items.get(data.item).then (item) ->
            doc.value = item.price


        @addItem(data.itemName).then (id) ->
          @_sales.add({
            item: id
            value: data.value
            date: data.date or (new Date()).toJSON().split('T')[0]
          }).then ->

  return Dispatcher
