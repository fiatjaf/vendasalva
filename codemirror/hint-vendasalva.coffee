store = require '../store.coffee'

module.exports = (editor, options) ->
  cursor = editor.getCursor()
  token = editor.getTokenAt cursor

  if token.state.is('item') and token.string.length > 1
    words = []
    for result in store.searchItem token.string
      word = result.ref
      if token.string.indexOf(word) == -1 # não sugerir coisas já escritas
        words.push word

    return {
      list: words
      from: {line: cursor.line, ch: token.start}
      to: {line: cursor.line, ch: token.end}
    }
