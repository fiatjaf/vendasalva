CodeMirror = require 'codemirror'

CodeMirror.defineMode 'vendasalva', require('./mode.coffee')
CodeMirror.defineExtension 'show-hint', require('./show-hint.js')(CodeMirror)
class CodeMirrorWidget
  type: 'Widget'
  constructor: (initialText, properties) ->
    @text = initialText
    @properties = properties
  init: ->
    elem = document.createElement 'div'
    elem.addEventListener 'DOMNodeInsertedIntoDocument', (e) =>
      @cm = CodeMirror elem, {
        mode: 'vendasalva'
        theme: 'blackboard'
        value: @text
      }
      @cm.focus()

      # autocompletion
      @cm.on 'keyup', (editor, e) =>
        e.preventDefault()
        return if editor.state.completionActive
        editor.showHint({
          hint: require('./hint-vendasalva.coffee')
          completeSingle: false
          completeOnSingleClick: true
        })

      # hook to cyclejs
      for property of @properties
        ((evHook) =>
          evName = evHook.substr(3)
          @cm.on evName, (cm, ev) =>
            if evHook.substr(0, 3) == 'ev-' and typeof @properties[evHook] == 'function'
              @properties[evHook]({cm: cm, ev: ev})
        )(property)
    return elem
  update: (prev, elem) ->
    cm = @cm or prev.cm
    if cm and cm.getValue() != @text
      cm.setValue @text
      cm.focus()

module.exports = CodeMirrorWidget
