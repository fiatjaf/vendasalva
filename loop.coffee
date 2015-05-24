raf = require('raf')
TypedError = require('error/typed')
InvalidUpdateInRender = TypedError(
  type: 'main-loop.invalid.update.in-render'
  message: 'main-loop: Unexpected update occurred in loop.\n' + 'We are currently rendering a view, ' + 'you can\'t change state right now.\n' + 'The diff is: {stringDiff}.\n' + 'SUGGESTED FIX: find the state mutation in your view ' + 'or rendering function and remove it.\n' + 'The view should not have any side effects.\n'
  diff: null
  stringDiff: null)

main = (initialState, view, channels, opts) ->
  opts = opts or {}
  currentState = initialState
  create = opts.create
  diff = opts.diff
  patch = opts.patch
  redrawScheduled = false

  tree = opts.initialTree or view(currentState, channels)
  target = opts.target or create(tree, opts)
  inRenderingTransaction = false
  currentState = null

  update = (state) ->
    if inRenderingTransaction
      throw InvalidUpdateInRender(
        diff: state._diff
        stringDiff: JSON.stringify(state._diff))
    if currentState == null and !redrawScheduled
      redrawScheduled = true
      raf redraw

    currentState = state
    return

  redraw = ->
    redrawScheduled = false
    return if currentState == null
    inRenderingTransaction = true
    try
      newTree = view(currentState, channels)
    catch e
      console.error "We had a problem while rendering the tree with the following state:", currentState
      console.debug "Aborting the render."
      inRenderingTransaction = false
      newTree = tree
      console.debug e.stack

    if opts.createOnly
      inRenderingTransaction = false
      create newTree, opts
    else
      patches = diff(tree, newTree, opts)
      inRenderingTransaction = false
      target = patch(target, patches, opts)
    tree = newTree
    currentState = null
    return

  return {
    target: target
    update: update
  }

module.exports = main
