jison = require('jison').Parser
fs = require 'fs'
grammar = fs.readFileSync 'day-parser.y', 'utf-8'
parser = jison grammar
input = '''
terra fruta:
20kg de tomate: R$ 350
=R$ 400


1kg laranja: R$ 50
1saco batata: R$ 40

pago: conta de luz: R$ 50
R$ 20 - 1 penca de bananas

PAGO: boleto terra fruta: 400
R$ 20 - taxa de incêndio : PAGAMENTO

2 caixas de ovo: 23

integral:
arroz, 10sacos: R$ 125,30
soja em grãos, 10sacos: R$ 77,25
+transporte: R$ 4,20
+ imposto: R$ 25,40
total: R$ 50
'''
console.log JSON.stringify parser.parse input
process.exit()
