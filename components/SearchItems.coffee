define ['components/DispatcherMixin', 'react'], (DispatcherMixin, React) ->
  {style, img, button, div, span, a, p, hr, label, fieldset, legend, table, tr, th, td, h1, h2, h3, h4, form, input, textarea} = React.DOM

  return React.createClass
    mixins: [DispatcherMixin]
    getInitialState: ->
      results: []

    updateSearchResult: (e) ->
      @dispatcher.searchItem(e.target.value).then (results) =>
        @setState results: results

    addItem: (e) ->
      name = e.target.value
      if name.length > 3
        @dispatcher.addItem name
        e.target.value = ''

    render: ->
      (div {},
        (input type: 'search', onChange: @updateSearchResult),
        (div {},
          (
            (div ref: item._id,
              item.name
            ) for item in @state.results
          )
        ),
        (input type: 'text', placeholder: 'ADD', onClick: @addItem)
      )




