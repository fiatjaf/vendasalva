
define(['react'], function(React) {
  return {
    propTypes: {
      dispatcher: React.PropTypes.object
    },
    childContextTypes: {
      dispatcher: React.PropTypes.object
    },
    getChildContext: function() {
      return {
        dispatcher: this.props.dispatcher
      };
    },
    contextTypes: {
      dispatcher: React.PropTypes.object
    },
    componentWillMount: function() {
      if (this.props.dispatcher) {
        return this.dispatcher = this.props.dispatcher;
      } else {
        return this.dispatcher = this.context.dispatcher;
      }
    }
  };
});
