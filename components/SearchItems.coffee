define ['components/DispatcherMixin', 'react'], (DispatcherMixin, React) ->
  {style, img, button, div, span, a, p, hr, label, fieldset, legend, table, tr, th, td, h1, h2, h3, h4, form, input, textarea} = React.DOM

  return React.createClass
    mixins: [DispatcherMixin]
    getInitialState: ->
      results: []

    getDefaultProps: ->
      onChange: ->

    updateSearchResult: (e) ->
      @dispatcher.searchItem(e.target.value).then (results) =>
        @setState results: results

    handleSelect: (item, e) ->
      @props.onChange item._id
      e.preventDefault()

    render: ->
      (div {},
        (input type: 'search', onChange: @updateSearchResult, value: @props.value),
        (div {},
          (
            (div
              ref: item._id
              onClick: @handleSelect.bind @, item
            , item.name) for item in @state.results
          )
        ),
      )




