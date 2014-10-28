jison = require('jison').Parser
fs = require 'fs'
grammar = fs.readFileSync 'day-parser.y', 'utf-8'
parser = jison grammar
input = '''
início do dia
ovo de codorna, 200g: R$ 20
bolo de banana, 1kg: 4,80
1kg açúcar mascavo: R$ 13,20
500g de cogumelo: 1 real
1 pacote de uvas: R$ 4,50
1kg de uvas :40 reais
R$ 4: cacau-em-pó, 400g
isto é um comentário
soja orgânica, 1 pct - 8 reais
1 pacote de rúcula: 5 reais
2 ramos de alface :50 cents
4 pencas de banana: R$ 2,25
3 pólen: 74,90 (desconto de 2,00)
nada aconteceu
29,90 por 2 bandejas de morangos
2 pcts de chá orgânico: R$ 23,40
2 mel: 8,20 (ficou devendo)
3 1/2 litros de leite (já estava pago)

INTEGRAL: 
4 pcts de sal: R$ 40
10kg de arroz integral cateto vermelho: R$ 150
20 caixas de biscoito: R$ 200
+ transporte: R$ 25
total: R$ 415

R$ 3: leite, 1 1/2l
3 reais por 1 34/67l de leite
1 banana: 20 centavos

terra fruta:
5 macarrão sem glúten: R$ 81,93
total: 84,20

fim do dia
'''
console.log JSON.stringify parser.parse input
process.exit()
