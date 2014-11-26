module.exports = ->
  startState: ->
    inCompra: false
  token: (stream, state) ->
    if stream.sol()
      state.state = null
      stream.eatSpace()

    # quant
    if not state.state and (stream.match(/\d+/) or stream.match(pack, false) or stream.match(meas, false))
      state.state = 'post-quant'
      stream.eatSpace()
      return 'number' if stream.match(meas) # '1 quilo' (ou 'quilo')
      if stream.match(pack)
        if stream.eatSpace() and stream.match('de') and stream.eatSpace() and stream.match(/\d+/)
          stream.eatSpace()
          return 'number' if stream.match(meas)
          # '1 pacote de 1 quilo' (ou 'pacote de 1 quilo')
      return 'number'
      # '1'

    # quant_sep
    else if state.state == 'post-quant' or state.state == 'post-item'
      stream.eatSpace()
      if state.state == 'post-quant'
        stream.match('de')
        state.state = 'item'
        stream.eatSpace()
        return 'keyword'
      else if state.state == 'post-item' and (stream.match(';') or stream.match(','))
        state.state = 'value'
        return 'keyword'

    # item
    else if state.state == 'item'
      if stream.skipTo(':')
        state.state = 'value'
        return 'variable-2'
      else if stream.skipTo(',') or stream.skipTo(';')
        state.state = 'post-item'
        return 'variable-2'

    # value/price
    else if state.state == 'value'
      stream.match(':')
      stream.eatSpace()
      stream.match(reai)
      stream.eatSpace()
      stream.match(/\d+(,\d{0,2})?/)
      stream.eatSpace()
      stream.match(reai)
      state.state = null
      return 'error'

    else if not state.state and stream.match(/sa[íi]da( p\/| para)?|entrada( de| do)?|retirada( p\/| para)?|entraram|pag(amento)?|entrou( do| de)?|conta|boleto|taxa|fatura|saldo|caixa|=|\+|-/i)
      return 'def'

    # compra
    else if not state.state and stream.match(/[A-Za-z\u0080-\u00FF0-9 ]+:/i)
      stream.eatSpace()
      if stream.eol()
        state.compra = true # not a state, just an indication
        return 'tag'

    else if not state.state and stream.match(/\+|-|=|total/)
      stream.skipToEnd()
      return 'keyword'

    else if stream.match(/^[\s \t]*$/)
      state.compra = false # a blank line ends 'compra'

    stream.skipToEnd()

  indent: (state, textAfter) ->
    if not state.compra
      return 0
    switch textAfter.trim()[0]
      when '=', '+', '-' then return 0
      else
        if textAfter.trim().substr(0, 5) == 'total'
          return -2
    return 2

pack = /u(nidades?)?|garrafas?|pencas?|bandejas?|bandejinhas?|vidros?|vdrs?|vds?|latas?|lts?|potes?|pts?|potinhos?|tantos?|punhados?|ramos?|pcts?|pacotes?|sacos?|saquinhos?|scs?|cxs?|caixas?/i
meas = /kgs?|quilos?|kilos?|gramas?|gs?|mls?|litros?|l/i
reai = /rea(is|l)|R\$|BRL|cent(avo)?s?/

#n: (stream, state) ->
#    ss
#  start: [
#    {
#      regex: /sa[íi]da( p\/| para)?|entrada( de| do)?|retirada( p\/| para)?|entraram|pag(amento)?|entrou( do| de)?|conta|boleto|taxa|fatura|saldo|caixa|=|\+|-/i
#      token: 'keyword'
#    }
#    {
#      regex: /cart([ãa]o)?|(cart[ãa]o +de +)?(cr[ée]d|d[eé]b)(ito)?|dinheiro|cheque|vezes|x/i
#      token: 'keyword'
#    }
#    {
#      regex: /[-A-Za-z\u0080-\u00FF0-9 ]+: *$/i
#      token: 'fornecedor'
#    }
#    {
#      regex: /:/
#      token: 'value_sep'
#    }
#    {
#      regex: /(R\$ *)?\d+(,\d\d)?|\d+(,\d\d)? *reais|\d+(,\d\d)? * centavos/i
#      token: 'price'
#    }
#    {
#      regex: /:/
#      token: 'value_sep'
#    }
#  ]
