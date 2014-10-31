jison = require('jison').Parser
fs = require 'fs'
grammar = fs.readFileSync 'day-parser.y', 'utf-8'
parser = jison grammar
input = '''
terra fruta:
20kg de tomate: R$ 350
=R$ 400

retirada: R$ 53
entrada - banco: R$ 200

1kg laranja: R$ 50
1saco batata: R$ 40

pago: conta de luz: R$ 50
R$ 20 - 1 penca de bananas

PAGO: boleto terra fruta: 400
R$ 20 - taxa de incêndio : PAGAMENTO
 entrada: é pro troco: 1,20

2 caixas de ovo: 23

integral:
arroz, 10sacos: R$ 125,30
soja em grãos, 10sacos: R$ 77,25
+transporte: R$ 4,20
+ imposto: R$ 25,40
total: R$ 50

entrada - troco do meu bolso: R$ 2,10

saída - caixa geral: 40,00

2 pacotinhos de chá de erva cidreira: R$ 20

caixa final: R$ 43,20
'''
console.log JSON.stringify parser.parse input
process.exit()
