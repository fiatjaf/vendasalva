jison = require('jison').Parser
fs = require 'fs'
grammar = fs.readFileSync 'day-parser.y', 'utf-8'
parser = jison grammar
input = '''
1kg laranja: R$ 50
1sc batata: R$ 40


integral:
arroz, 10sacos: R$ 125,30
soja em grãos, 10sacos: R$ 77,25
+ transporte: R$ 4
+ imposto: R$ 25
total: R$ 50
'''
console.log JSON.stringify parser.parse input
process.exit()
