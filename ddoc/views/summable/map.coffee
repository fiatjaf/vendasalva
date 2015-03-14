(doc) ->

  `
  var ~ import parser ~
  `

  string_day = doc._id
  parts = string_day.split('-')
  year = parseInt parts[0]
  month = parseInt parts[1]
  day = parseInt parts[2]
  week = (->
    d = new Date(Date.parse string_day)
    d.setHours(0, 0, 0)
    d.setDate(d.getDate()+4-(d.getDay() or 7))
    Math.ceil (((d-new Date(d.getFullYear(),0,1))/8.64e7)+1)/7
  )()

  facts = parser.parse(doc.raw)

  receita = 0

  for fact in facts
    switch fact.kind
      when 'venda'
        receita += fact.value
        emit ['item-venda', fact.item, string_day], fact.value
      when 'compra'
        common_costs = fact.total - sum(fact.items.map((i) -> i.value))
        proportional = common_costs / fact.total
        for item in fact.items
          individual_price = item.value / item.q
          emit ['item-compra', item.item, string_day], (item.value/item.q)

  emit ['receita', year, month, week, day], receita
