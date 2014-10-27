jison = require('jison').Parser
fs = require 'fs'
grammar = fs.readFileSync 'day-parser.y', 'utf-8'
console.log grammar
parser = jison grammar
input = '''
        ovo de codorna, 200g
        bolo de banana, 1kg: 4,80
        1kg açúcar mascavo
        500g de cogumelo: 1 real
        1 pacote de uvas
        1kg de uvas
        R$ 4: cacau-em-pó, 400g
        soja orgânica, 1 pct
        1 pacote de rúcula: 5 reais
        2 ramos de alface
        4 pencas de banana
        3 pólen: 74,90 (desconto de 2,00)
        29,90 por 2 bandejas de morangos
        2 pcts de chá orgânico: R$ 23,40
        2 mel: 8,20 (ficou devendo)
        3 1/2 litros de leite (já estava pago)
        R$ 3: leite, 1 1/2l
        3 reais por 1 34/67l de leite
        '''
console.log input
console.log parser.parse input
process.exit()

textarea = '''
vendas:
300g de tomate
1 bolo de banana - 6,50
2 pólen: 23,55
1kg de banana, R$ 22
1,5kg mandioca, 6,50 (mariana ficou devendo)
alho, 32g, 2,50
pacote de germen de trigo: R$ 6,80
batata, R$ 4 (maria - não pagou)

retiradas:
marcia: 150,00
ana: R$ 220



caixa:
fim do dia: R$ 430,40
almoço: 250,80

perdeu:
3 latas de cogumelo
3kg de beringela
2 ramos de espinafre
1 rúcula (ramo)
'''

expected =
  vendas: [
    item: 'tomate'
    unity: 'g'
    quantity: 300
    value: undefined
  ,
    item: 'bolo de banana'
    unity: 'u'
    quantity: 1
    value: 650
  ,
    item: 'pólen'
    unity: 'u'
    quantity: 2
    value: 2355
  ,
    item: 'banana'
    unity: 'kg'
    quantity: 1
    value: 2200
  ,
    item: 'mandioca'
    unity: 'kg'
    quantity: 1.5
    value: 650
  ,
    item: 'alho'
    unity: 'kg'
    quantity: 0.032
    value: 250
  ,
    item: 'germen de trigo'
    unity: 'pacote'
    quantity: 1
    value: 680
  ,
    item: 'batata'
    unity: undefined
    quantity: undefined
    value: 400
  ]

  notes: [
    note: 'mariana ficou devendo'
    target:
      vendas: 4
  ,
    note: 'maria - não pagou'
    target:
      vendas: 7
  ]

  retiradas: [
    target: 'marcia'
    value: 15000
  ,
    target: 'ana'
    value: 22000
  ]

  caixa:
    'fim do dia': 43040
    'almoço': 25080

  perdeu: [
    item: 'cogumelo'
    unity: 'lata'
    quantity: 3
  ,
    item: 'beringela'
    unity: 'kg'
    quantity: 3
  ,
    item: 'espinafre'
    unity: 'ramo'
    quantity: 2
  ,
    item: 'rúcula'
    unity: 'ramo'
    quantity: 1
  ]

diff = require 'diff-deep'

console.log diff.diff expected, parser.parse textarea
