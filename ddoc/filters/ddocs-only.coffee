(doc) ->
  if doc._id.substr(0, 8) == '_design/'
    true
  else
    false
