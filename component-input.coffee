hg               = require 'mercury'
Titulo           = require('titulo').toLaxTitleCase
date             = require 'date-extended'

store            = require './store.coffee'
CodeMirrorWidget = require './codemirror/vendasalva-widget.coffee'
vrenderTable     = require './vrender-table.coffee'

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
  activeDay = state.activeDay()
  rawInput = cmData.cm.getValue()
  return if rawInput == state.rawInput()

  localStorage.setItem activeDay + ':raw', rawInput
  state.usingLocalCache.set true
  state.rawInput.set rawInput

Input = (options={}) ->
  state = hg.state
    usingLocalCache: hg.value false
    activeDay: hg.value date.format(new Date, 'yyyy-MM-dd')
    rawInput: hg.value ''

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
  parsed = parse state.rawInput

  customClass = if not parsed then 'error' else if state.usingLocalCache then 'local-cache' else 'saved'

  (div className: 'dashboard',
    (div className: 'full',
      (h1 {},
        if (new Date).toISOString().split('T')[0] == state.activeDay then 'Hoje, ' else ''
        state.activeDay.split('-').reverse().join('/')
      )
    )
    (div className: 'half',
      (div className: 'day ' + customClass,
        (button
          className: 'primary'
          'ev-click': hg.sendClick state.channels.saveInputText
        , 'Salvar')
        (new CodeMirrorWidget(state.rawInput, {
          'ev-change': state.customHandlers.inputTextChanged
        }))
      )
    )
    (div className: 'half',
      (div id: 'facts',
        (div className: 'vendas',
          (h2 {}, 'Vendas')
          (h3 {}, "Total: R$ #{Reais.fromInteger parsed.receita}")
          (vrenderTable
            className: 'primary'
            data: parsed.vendas
            columns: ['Quant','Produto','Valor pago','Forma de pagamento']
          )
        ) if parsed.vendas.length
        (div className: 'compras',
          (h2 {}, 'Compras')
          (ul {},
            (li {},
              (h3 {}, Titulo compra.fornecedor)
              (vrenderTable
                className: 'warning'
                data: compra.items
                columns: ['Quant', 'Produto', 'Preço total', 'Preço unitário']
              )
              (div {},
                "+ #{Titulo extra.desc}: R$ #{Reais.fromInteger extra.value}"
              ) for extra in compra.extras if compra.extras
              (h4 {}, "Total: R$ #{Reais.fromInteger compra.total}") if compra.total
            ) for compra in parsed.compras
          )
        ) if parsed.compras.length
        (div className: 'contas',
          (h2 {}, 'Pagamentos')
          (vrenderTable
            className: 'error'
            data: parsed.contas
            columns: ['Conta', 'Valor']
          )
        ) if parsed.contas.length
        (div className: 'caixa',
          (h2 {}, 'Caixa')
          (table className: 'success',
            (thead {},
              (tr {},
                (th {})
                (th {}, 'Saídas')
                (th {}, 'Entradas')
              )
            )
            (tbody {},
              (tr {},
                (td {}, Titulo row.desc)
                (td {}, if row.value < 0 then 'R$ ' + Reais.fromInteger row.value else null)
                (td {}, if row.value > 0 then 'R$ ' + Reais.fromInteger row.value else null)
              ) for row in parsed.caixa
            ) if parsed.caixa
            (tfoot {},
              (tr {},
                (th {colspan: 3}, 'R$ ' + Reais.fromInteger parsed.caixa.saldo)
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
  caixa = [{desc: 'Vendas', value: 0}]
  caixa.saldo = 0
  receita = 0
  for fact in facts
    fact.value = parseFloat(fact.value) or 0

    switch fact.kind
      when 'venda'
        vendas.push {
          'Quant': fact.q
          'Produto': "#{Titulo fact.item} (#{fact.u})"
          'Valor pago': 'R$ ' + Reais.fromInteger fact.value
          'Forma de pagamento': fact.pagamento + if fact.x then " (#{fact.x}x)" else ''
        }
        caixa[0].value += fact.value if fact.pagamento == 'dinheiro'
        caixa.saldo += fact.value
        receita += fact.value
      when 'compra'
        compra = fact
        comprados = compra.items or []
        compra.items = []
        for item in comprados
          compra.items.push {
            'Quant': item.q
            'Produto': "#{Titulo item.item} (#{item.u})"
            'Preço total': 'R$ ' + Reais.fromInteger item.value
            'Preço unitário': 'R$ ' + Reais.fromInteger item.value/item.q
          }
        compras.push compra
      when 'conta'
        contas.push {
          'Conta': fact.desc
          'Valor': 'R$ ' + Reais.fromInteger fact.value
        }
      when 'entrada'
        caixa.push fact
        caixa.saldo += fact.value
      when 'saída'
        fact.value = -fact.value
        caixa.push fact
        caixa.saldo += fact.value
      when 'saída/conta'
        fact.value = -fact.value
        caixa.push fact
        caixa.saldo += fact.value
        contas.push {
          'Conta': fact.desc
          'Valor': 'R$ ' + Reais.fromInteger fact.value
        }
      when 'comment' then comments.push fact

  vendas: vendas
  compras: compras
  contas: contas
  comments: comments
  caixa: caixa
  receita: receita

Input.buildRenderer = (state) -> vrender.bind null, state

module.exports = Input
