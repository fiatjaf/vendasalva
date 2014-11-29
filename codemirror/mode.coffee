module.exports = ->
  startState: ->
    compra: false
    lastState: null
    presentState: null
    is: (x) -> x == @presentState
    was: (x) -> x == @lastState
    willBe: (x) ->
      @lastState = @presentState
      @presentState = x
  token: (___, S) ->
    if S.notSol
      S.notSol = false
    else if ___.sol()
      S.willBe null #
      S.willBe null # ensure the history is cleaned
      ___.eatSpace()

    # price
    if S.is('price')
      ___.eatSpace()
      r = ___.match(reai)
      ___.eatSpace()
      ___.match(/\d+(,\d{0,2})?/)
      ___.eatSpace()
      r = r or ___.match(reai)

      if ___.match(' *:', false)
        S.willBe 'value_sep'
      else
        S.willBe null
      return 'error'
    else if S.is(null) and ___.match(pric, false)
      S.notSol = true
      S.willBe 'price'
      return 'error'
    # /price

    # quant
    else if S.is('quant')
      S.willBe 'quant_sep' # sometimes it will be value_sep, but this way works,
      ___.match(quan)      #         it will reach the correct state indirectly.
      ___.eatSpace()
      return 'number' if ___.match(meas) # '1 quilo' (ou 'quilo')
      if ___.match(pack)
        if ___.eatSpace() and ___.match('de') and ___.eatSpace() and ___.match(/\d+/)
          ___.eatSpace()
          return 'number' if ___.match(meas) # '1 pacote de 1 quilo' (ou 'pacote de 1 quilo')
      return 'number' # '1'
    else if S.is(null) and (___.match(/\d+(,\d+)?/) or ___.match(meas, false))
      S.willBe 'quant'
      return 'number'
    # /quant

    # quant_sep
    else if S.is('quant_sep')
      ___.eatSpace()
      ___.match('de') or ___.match(';') or ___.match(',')
      ___.eatSpace()
      if S.was 'quant' then S.willBe 'item' else S.willBe 'quant'
      return 'keyword'

    # value_sep
    else if S.is('value_sep')
      ___.next() # eat the ':'
      ___.eatSpace()
      if S.was('item') or S.was('quant')
        S.willBe 'price' # 2kg banana: R$ 30 | banana, 2kg: R$ 30
      else if S.was 'price'
        if ___.match(/\d/, false)
          S.willBe 'quant' # R$ 22: 2kg de ...
        else if ___.match(/[A-Za-z\u0080-\u00FF0-9 ]/i, false)
          S.willBe 'item' # R$ 43: banana
      return 'keyword'

    # specific lines
    else if S.is(null) and ___.match(/sa[íi]da( p\/| para)?|entrada( de| do)?|retirada( p\/| para)?|entraram|pag(amento)?|entrou( do| de)?|conta|boleto|taxa|fatura|saldo|caixa|=|\+|-/i)
      return 'def'

    # compra
    else if S.is(null) and ___.match(/[A-Za-z\u0080-\u00FF0-9 ]+:/i)
      ___.eatSpace()
      if ___.eol()
        S.compra = true # not a state, just an indication
        return 'tag'
    else if S.is(null) and ___.match(/\+|-|=|total/)
      ___.skipToEnd()
      return 'keyword'
    else if ___.match(/^[\s \t]*$/)
      S.compra = false # a blank line ends 'compra'
    # /compra

    # item (in the end because we first have to test saldo, pagamento etc)
    else if S.is('item')
      if ___.skipTo(':')
        S.willBe 'value_sep'
        return 'variable-2'
      else if ___.skipTo(',') or ___.skipTo(';')
        S.willBe 'post-item'
        return 'variable-2'
    else if S.is(null) and ___.match(/[A-Za-z\u0080-\u00FF0-9 ]+[;,]/, false)
      S.willBe 'item' # only to give the correct .was to the next
      ___.match(/[A-Za-z\u0080-\u00FF0-9 ]+/)
      S.willBe 'quant_sep'
      return 'variable-2'
    # /item

    # comment
    if S.is(null)
      ___.skipToEnd()
      return 'comment'

    ___.skipToEnd()

  indent: (S, textAfter) ->
    if not S.compra
      return 0
    switch textAfter.trim()[0]
      when '=', '+', '-' then return 0
      else
        if textAfter.trim().substr(0, 5) == 'total'
          return 0
    return 2

pack = /u(nidades?)?|garrafas?|pencas?|bandejas?|bandejinhas?|vidros?|vdrs?|vds?|latas?|lts?|potes?|pts?|potinhos?|tantos?|punhados?|ramos?|pcts?|pacotes?|sacos?|saquinhos?|scs?|cxs?|caixas?/i
meas = /kgs?|quilos?|kilos?|gramas?|gs?|mls?|litros?|l/i
reai = /rea(is|l)|R\$|BRL|cent(avo)?s?/
pric = /(R\$ *)?\d+(,\d+)?( *rea(is|l))? *:/
quan = /\d+(,\d+)?/
