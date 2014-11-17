PEG      = require 'pegjs'
fs       = require 'fs'
path     = require 'path'
should   = require('chai').should()

parser = PEG.buildParser fs.readFileSync path.resolve(__dirname, '../dia.peg'), encoding: 'utf-8'

test = '''
INTEGRAL:
4 pcts de sal: R$ 40,1
10kg de arroz integral cateto vermelho: R$ 150
20 caixas de biscoito: R$ 200
+ transporte: R$ 25
total: R$ 415

terra mar:
5 macarrão sem glúten: R$ 81,93
total: 84,20

terra fruta:
20kg de tomate: R$ 350
=R$ 400

integral:
10sacos de arroz: R$ 125,30
soja em grãos, 10sacos: R$ 77,25
+transporte: R$ 4,20
+ imposto: R$ 25,40
total: R$ 50

adsad:
20g de sdas: R$ 40
20 kilos; qwe sad: 60,90 reais
+ nada: R$ 0
=R$ 40
'''

res = parser.parse test

res[0].total.should.equal 41510
res[0].extras.should.have.length 2
res[0].items.should.have.length 3
res[0].items[2].should.deep.equal {u: 'caixa', q: 20, item: 'biscoito', value: 20000}
