_          = require 'setimmediate'
Titulo     = require('titulo').toLaxTitleCase
Reais      = require 'reais'
PEG        = require 'pegjs'

dayParser = parse: -> [] # provisory
fullParse = (rawInput) ->
  try
    facts = dayParser.parse rawInput
  catch e
    console.log e
    return null

  vendas = []
  compras = []
  contas = []
  comments = []
  receita = 0

  caixa =
    periods: [ # each period is delimited by the occurrence of a 'saldo'

    ]
    final: [{desc: 'Vendas', value: 0}]
  caixa.final.saldo =
    esperado: 0
    real: 0
  caixa.addPeriod = ->
    period = [{desc: 'Vendas', value: 0}]
    period.saldo =
      esperado: if caixa.periods.length then caixa.periods[caixa.periods.length-1].saldo.real else 0
      real: null
    caixa.periods.push period

  caixa.addPeriod()
  updateFirstPeriod = false
  if not facts.length or facts[0].kind != 'saldo'
    caixa.addPeriod()
    updateFirstPeriod = true

  for fact in facts
    fact.value = parseFloat(fact.value) or 0
    caixaPeriod = caixa.periods[caixa.periods.length-1]

    switch fact.kind
      when 'venda'
        fact.pagamento = if not fact.pagamento then '-' else fact.pagamento
        vendas.push {
          'Quant': fact.q
          'Produto': "#{Titulo fact.item} (#{fact.u})"
          'Valor': Reais.fromInteger(fact.value, 'R$ ')
          'Pagamento': fact.pagamento + if fact.x then " (#{fact.x}x)" else ''
          '_title': (if fact.note then fact.note + ' ' else '') + if fact.cliente then "(cliente: #{fact.cliente})" else ''
        }
        receita += fact.value
        if fact.pagamento == 'dinheiro'
          caixaPeriod[0].value += fact.value
          caixaPeriod.saldo.esperado += fact.value
          caixa.final[0].value += fact.value
          caixa.final.saldo.esperado += fact.value
      when 'compra'
        compra = fact
        comprados = compra.items or []
        compra.items = []
        for item in comprados
          compra.items.push {
            'Quant': item.q
            'Produto': "#{Titulo item.item} (#{item.u})"
            'Preço total': Reais.fromInteger(item.value, 'R$ ')
            'Preço unitário': Reais.fromInteger(item.value/item.q, 'R$ ')
          }
        compras.push compra
      when 'conta'
        contas.push {
          'Conta': fact.desc
          'Valor': Reais.fromInteger(fact.value, 'R$ ')
        }
      when 'entrada'
        caixaPeriod.push fact
        caixaPeriod.saldo.esperado += fact.value
        caixa.final.push fact
        caixa.final.saldo.esperado += fact.value
      when 'saída'
        fact.value = -fact.value
        caixaPeriod.push fact
        caixaPeriod.saldo.esperado += fact.value
        caixa.final.push fact
        caixa.final.saldo.esperado += fact.value
      when 'saída/conta'
        fact.value = -fact.value
        caixaPeriod.push fact
        caixaPeriod.saldo.esperado += fact.value
        caixa.final.push fact
        caixa.final.saldo.esperado += fact.value
        contas.push {
          'Conta': fact.desc
          'Valor': Reais.fromInteger(fact.value, 'R$ ')
        }
      when 'saldo'
        caixaPeriod.saldo.real = fact.value
        caixaPeriod.saldo.desc = fact.desc

        if updateFirstPeriod and caixaPeriod == caixa.periods[1]
          # if we don't have the initial saldo, assume it is right according to the first time
          # a saldo is given.
          caixa.periods[0].saldo.real = caixaPeriod.saldo.real - caixaPeriod.saldo.esperado
          caixaPeriod.saldo.esperado = caixaPeriod.saldo.real

          # also update the global (final) saldo esperado, as explained in the next if clause
          caixa.final.saldo.esperado += caixa.periods[0].saldo.real

        else if caixaPeriod == caixa.periods[0]
          # if this is the initial saldo, update the global (final) saldo esperado
          # to reflect the value declared to be the initial
          caixa.final.saldo.esperado += caixaPeriod.saldo.real

        caixa.addPeriod()
      when 'comment' then comments.push fact

  # post processing
  if facts.length and facts[facts.length-1].kind != 'saldo'
    caixa.addPeriod()
  caixa.final.saldo.real = caixa.periods[caixa.periods.length-2].saldo.real

  vendas: vendas
  compras: compras
  contas: contas
  comments: comments
  caixa: caixa
  receita: receita

nextTick = if setImmediate then setImmediate else (fn) -> setTimeout(fn, 0)

queue = (->
  next = null
  doing = null

  execute = ->
    doing = true
    nextTick ->
      task = next
      next = null
      task() if task
      if next
        execute()
      else
        doing = false

  return (task) ->
    next = task
    if not doing
      execute()
  )()

module.exports = (self) ->
  setupDayParser = (e) ->
    # will be passed the grammar
    grammar = e.data
    dayParser = PEG.buildParser grammar

    # after receiving the grammar and building the parser,
    # we start receiving normal "parse this please" messages
    self.removeEventListener 'message', setupDayParser
    self.addEventListener 'message', (e) ->
      task = ->
        day = e.data[0]
        raw = e.data[1]
        parsed = fullParse raw
        delete parsed.caixa.addPeriod
        self.postMessage [day, parsed]
      queue task

  self.addEventListener 'message', setupDayParser
