hg               = require 'mercury'
Titulo           = require('titulo').toLaxTitleCase
date             = require 'date-extended'

store            = require './store.coffee'
CodeMirrorWidget = require './codemirror/vendasalva-widget.coffee'
vrenderTable     = require './vrender-table.coffee'

nextTick = if setImmediate then setImmediate else (fn) -> setTimeout(fn, 0)

updateDay = (state, day) ->
  store.get(day).then((doc) ->
    raw = checkLocalCache state, day, doc

    state.rawInput.set raw
    state.activeDay.set day
  )

checkLocalCache = (state, day, doc) ->
  local_raw = localStorage.getItem day + ':raw'
  doc_rev = if doc then parseInt(doc._rev.split('-')[0]) else 0

  # everything only matters if there is a cached version
  if local_raw
    local_rev = parseInt(localStorage.getItem day + ':rev_number') or 0

    # we override it if the pouchdb version is newer
    if doc and doc_rev > local_rev
      raw = doc.raw
      state.usingLocalCache.set false
      localStorage.setItem day + ':raw', ''
      localStorage.setItem day + ':rev_number', doc_rev

    # otherwise we keep using it
    else
      state.usingLocalCache.set true
      raw = local_raw

  # if we don't have any cache, use the pouchdb doc
  # and init the cache (doc_rev will be 0)
  else if doc
    raw = doc.raw
    state.usingLocalCache.set false
    localStorage.setItem day + ':rev_number', doc_rev

  # or start a new thing
  else
    raw = ''
    state.usingLocalCache.set false
    localStorage.setItem day + ':rev_number', 0

  return raw

inputTextChanged = (state, cmData) ->
  # only react to big events (newline, big deletions, multiline pastes)
  if cmData.ev
    ev = cmData.ev[0]
    if ev.text.length < 2 and ev.removed.length < 2
      return

  activeDay = state.activeDay()
  rawInput = cmData.cm.getValue()
  return if rawInput == state.rawInput()

  localStorage.setItem activeDay + ':raw', rawInput
  state.usingLocalCache.set true
  state.rawInput.set rawInput

  # parse asynchronously
  nextTick ->
    state.parsedInput.set parse rawInput

Input = (options={}) ->
  state = hg.state
    usingLocalCache: hg.value false
    activeDay: hg.value date.format(new Date, 'yyyy-MM-dd')
    rawInput: hg.value ''
    parsedInput: hg.value null

    channels:
      saveInputText: (state, data) ->
        activeDay = state.activeDay()
        store.get(activeDay).then((doc) ->
          if not doc
            doc = {_id: activeDay}
          doc.raw = state.rawInput()
          store.save(doc).then(->
            localStorage.removeItem activeDay + ':raw'
            localStorage.removeItem activeDay + ':rev_number'
            state.usingLocalCache.set false
          )
        )

    customHandlers: hg.varhash {}

  state.customHandlers.put('inputTextChanged', hg.value inputTextChanged.bind null, state)
  state.customHandlers.put('updateDay', hg.value updateDay.bind null, state)

  return state

{div, h1, h2, h3, h4, h5, h6, button, pre,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrender = (state) ->
  parsed = state.parsedInput
  customClass = if not parsed then 'error' else if state.usingLocalCache then 'local-cache' else 'saved'

  (div className: 'dashboard',
    (div className: 'full',
      (h1 {},
        if (new Date).toISOString().split('T')[0] == state.activeDay then 'Hoje, ' else ''
        state.activeDay.split('-').reverse().join('/')
      )
    )
    (div className: 'col-md-6',
      (div className: 'day ' + customClass,
        (button
          className: 'btn btn-primary'
          'ev-click': hg.sendClick state.channels.saveInputText
        , 'Salvar')
        (new CodeMirrorWidget(state.rawInput, {
          'ev-changes': state.customHandlers.inputTextChanged
          'ev-blur': state.customHandlers.inputTextChanged
          'ev-scroll': state.customHandlers.inputTextChanged
          'ev-focus': state.customHandlers.inputTextChanged
        }))
      )
    )
    (div className: 'col-md-6',
      (div id: 'facts',
        (div className: 'vendas',
          (h2 {}, 'Vendas')
          (h3 {}, "Total: " + Reais.fromInteger(parsed.receita, 'R$ '))
          (vrenderTable
            style: 'info'
            data: parsed.vendas
            columns: ['Quant','Produto','Valor','Pagamento']
          )
        ) if parsed.vendas.length
        (div className: 'compras',
          (h2 {}, 'Compras')
          (ul {},
            (li {},
              (h3 {}, Titulo compra.fornecedor)
              (vrenderTable
                style: 'warning'
                data: compra.items
                columns: ['Quant', 'Produto', 'Preço total', 'Preço unitário']
              )
              (div {},
                "+ #{Titulo extra.desc}: " + Reais.fromInteger(extra.value, 'R$ ')
              ) for extra in compra.extras if compra.extras
              (h4 {}, "Total: " + Reais.fromInteger(compra.total, 'R$ ')) if compra.total
            ) for compra in parsed.compras
          )
        ) if parsed.compras.length
        (div className: 'contas',
          (h2 {}, 'Pagamentos')
          (vrenderTable
            style: 'danger'
            data: parsed.contas
            columns: ['Conta', 'Valor']
          )
        ) if parsed.contas.length
        (div className: 'caixa',
          (h2 {}, 'Caixa')
          (table className: 'table table-bordered table-hover',
            (thead {},
              (tr className: 'active',
                (th {})
                (th {}, 'Saídas')
                (th {}, 'Entradas')
              )
            )
            (tbody {},
              (->
                rows = []

                for caixaPeriod, pn in parsed.caixa.periods
                  for row in caixaPeriod
                    if row.value # skip blank
                      rows.push (tr {},
                        (td {}, Titulo row.desc)
                        (td {}, if row.value < 0 then Reais.fromInteger(row.value, 'R$ ') else null)
                        (td {}, if row.value > 0 then Reais.fromInteger(row.value, 'R$ ') else null)
                      )

                  if pn+2 < parsed.caixa.periods.length and # don't show partials for the last period
                     pn != 0 # don't show partials for the first period
                    rows.push (tr className: 'info',
                      (th {},
                        'Saldo parcial esperado' +
                        if caixaPeriod.saldo.desc then " (#{caixaPeriod.saldo.desc})" else ''
                      )
                      (th {attributes: {colspan: 2}}, Reais.fromInteger(caixaPeriod.saldo.esperado, 'R$ '))
                    )
                    rows.push (tr className: 'info',
                      (th {},
                        'Saldo parcial real' +
                        if caixaPeriod.saldo.desc then " (#{caixaPeriod.saldo.desc})" else ''
                      )
                      (th {attributes: {colspan: 2}}, Reais.fromInteger(caixaPeriod.saldo.real, 'R$ '))
                    )

                  else if pn == 0 # for the first period, show one row
                    rows.push (tr {className: 'success'},
                     (th {}, 'Saldo inicial')
                     (th {attributes: {colspan: 2}}, Reais.fromInteger(caixaPeriod.saldo.real, 'R$ '))
                    )

                return rows
              )()
            ) if parsed.caixa
            (tfoot {},
              (tr className: 'success',
                (th {}, 'Saldo final esperado')
                (th {attributes: {colspan: 2}}, Reais.fromInteger(parsed.caixa.final.saldo.esperado, 'R$ '))
              )
              (tr className: 'success',
                (th {}, 'Saldo final real')
                (th {attributes: {colspan: 2}}, Reais.fromInteger(parsed.caixa.final.saldo.real, 'R$ '))
              )
            )
          )
        )
        (div className: 'notas',
          (h2 {}, 'Anotações')
          (pre {key: i}, c.note) for c, i in parsed.comments
        ) if parsed.comments.length
      ) if parsed
    )
  )

parse = (rawInput) ->
  try
    facts = store.parseDay rawInput
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

Input.buildRenderer = (state) -> vrender.bind null, state

module.exports = Input
