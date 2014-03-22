define ['promise', 'stores/item'], (Promise, ItemStore) ->
  class Dispatcher
    _items: new ItemStore()

    constructor: ->

    searchItem: (str) ->
      return new Promise (resolve) =>
        @_items.search(str).then (ids) ->
          console.log ids
          resolve ids

    addItem: (name) ->
      return new Promise (resolve) =>
        @_items.add(name).then (res) ->
          console.log res
          resolve res

  return Dispatcher
