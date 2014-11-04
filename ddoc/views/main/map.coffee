(doc) ->

  `
  ~ import parser ~
  `

  day = doc._id
  facts = parser.parse(doc.raw)

  for fact in facts
    switch fact.kind
      when 'venda'
        emit ['price', fact.item, day, 'venda'], fact.value/fact.q
