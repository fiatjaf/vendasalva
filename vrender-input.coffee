hg               = require 'mercury'
Titulo           = require('titulo').toLaxTitleCase

CodeMirrorWidget = require './codemirror/vendasalva-widget.coffee'
vrenderTable     = require './vrender-table.coffee'

{div, h1, h2, h3, h4, h5, h6, button, pre,
 table, thead, tbody, tfoot, tr, th, td,
 ul, li} = require 'virtual-elements'

vrenderInput = (state, channels) ->
  parsed = state.input.parsedInput
  customClass = if not parsed then 'error' else if state.input.usingLocalCache then 'local-cache' else 'saved'

  (div className: 'dashboard',
    (div className: 'full',
      (h1 {},
        if (new Date).toISOString().split('T')[0] == state.input.activeDay then 'Hoje, ' else ''
        state.input.activeDay.split('-').reverse().join('/')
      )
    )
    (div className: 'col-md-6',
      (div className: 'day ' + customClass,
        (button
          className: 'btn btn-primary'
          'ev-click': hg.sendClick channels.saveInputText
        , 'Salvar')
        (new CodeMirrorWidget(state.input.rawInput, {
          'ev-changes': channels.inputTextChanged
          'ev-blur': channels.inputTextChanged
          'ev-scroll': channels.inputTextChanged
          'ev-focus': channels.inputTextChanged
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

module.exports = vrenderInput
