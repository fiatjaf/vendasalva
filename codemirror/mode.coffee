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
    if ___.sol()
      S.willBe null
      ___.eatSpace()

    # quant
    if S.is(null) and (___.match(/\d+/) or ___.match(pack, false) or ___.match(meas, false))
      S.willBe 'post-quant'
      ___.eatSpace()
      return 'number' if ___.match(meas) # '1 quilo' (ou 'quilo')
      if ___.match(pack)
        if ___.eatSpace() and ___.match('de') and ___.eatSpace() and ___.match(/\d+/)
          ___.eatSpace()
          return 'number' if ___.match(meas)
          # '1 pacote de 1 quilo' (ou 'pacote de 1 quilo')
      return 'number'
      # '1'

    # quant_sep
    else if S.is('post-quant')
      ___.eatSpace()
      if S.is('post-quant')
        ___.match('de')
        S.willBe 'item'
        ___.eatSpace()
        return 'keyword'

    # value_sep
    else if S.is('value_sep')
      ___.next() # eat the ':'
      ___.eatSpace()
      if S.was 'item'
        S.willBe 'price' # ... banana: R$ 30
      else if S.was 'price'
        if ___.match(/\d/, false)
          S.willBe 'quant' # R$ 22: 2kg de ...
        else if ___.match(/[A-Za-z\u0080-\u00FF0-9 ]/i, false)
          S.willBe 'item' # R$ 43: banana
      return 'keyword'

    # item
    else if S.is('item')
      if ___.skipTo(':')
        S.willBe 'value_sep'
        return 'variable-2'
      else if ___.skipTo(',') or ___.skipTo(';')
        S.willBe 'post-item'
        return 'variable-2'

    # price
    else if S.is('price')
      ___.match(':')
      ___.eatSpace()
      ___.match(reai)
      ___.eatSpace()
      ___.match(/\d+(,\d{0,2})?/)
      ___.eatSpace()
      ___.match(reai)
      S.willBe null
      return 'error'

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
