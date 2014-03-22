define ['stores/items'], (ItemsStore) ->
  items = new ItemsStore()
  
  class Dispatcher
    constructor: ->

    searchItem: (str) ->
      items.search(str).then (ids) ->
        console.log ids

    addItem: (name, price, quantity) ->
      return
