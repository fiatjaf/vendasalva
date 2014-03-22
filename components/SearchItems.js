
define(['components/DispatcherMixin', 'react'], function(DispatcherMixin, React) {
  var a, button, div, fieldset, form, h1, h2, h3, h4, hr, img, input, label, legend, p, span, style, table, td, textarea, th, tr, _ref;
  _ref = React.DOM, style = _ref.style, img = _ref.img, button = _ref.button, div = _ref.div, span = _ref.span, a = _ref.a, p = _ref.p, hr = _ref.hr, label = _ref.label, fieldset = _ref.fieldset, legend = _ref.legend, table = _ref.table, tr = _ref.tr, th = _ref.th, td = _ref.td, h1 = _ref.h1, h2 = _ref.h2, h3 = _ref.h3, h4 = _ref.h4, form = _ref.form, input = _ref.input, textarea = _ref.textarea;
  return React.createClass({
    mixins: [DispatcherMixin],
    getInitialState: function() {
      return {
        results: []
      };
    },
    updateSearchResult: function(e) {
      var _this = this;
      return this.dispatcher.searchItem(e.target.value).then(function(results) {
        return _this.setState({
          results: results
        });
      });
    },
    addItem: function(e) {
      var name;
      name = e.target.value;
      if (name.length > 3) {
        this.dispatcher.addItem(name);
        return e.target.value = '';
      }
    },
    render: function() {
      var item;
      return div({}, input({
        type: 'search',
        onChange: this.updateSearchResult
      }), div({}, (function() {
        var _i, _len, _ref2, _results;
        _ref2 = this.state.results;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          item = _ref2[_i];
          _results.push(div({
            ref: item._id
          }, item.name));
        }
        return _results;
      }).call(this)), input({
        type: 'text',
        placeholder: 'ADD',
        onClick: this.addItem
      }));
    }
  });
});
