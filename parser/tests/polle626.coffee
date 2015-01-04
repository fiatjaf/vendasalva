PEG      = require 'pegjs'
fs       = require 'fs'
path     = require 'path'
should   = require('chai').should()

parser = PEG.buildParser fs.readFileSync path.resolve(__dirname, '../dia.peg'), encoding: 'utf-8'

test = '''
maracujá, 2kg: 1,80
1 saco de feijão: 2,10
7 sacos de mandioca: 9,00: cartão de débito
1 garrafa de 700ml de vinagre de maçã: 1,00

solarius:
10 potes de manjar branco dos deuses: 2662,00
6 sacos de formiga da terra: 662,00
+Frete: 50,00
Total: 10000,00

saída para conta de luz: 20,00
'''

res = parser.parse test

try
  res[0].should.deep.equal {u: 'kg', q: 2, item: 'maracujá', value: 180, pagamento: 'dinheiro', kind: 'venda'}
  res[1].u.should.equal 'saco'
  res[1].item.should.equal 'feijão'
  res[2].pagamento.should.equal 'débito'
  res[2].value.should.equal 900
  res[3].u.should.equal 'garrafa/700ml'
  res[4].kind.should.equal 'compra'
  res[4].fornecedor.should.equal 'solarius'
  res[4].items[0].item.should.equal 'manjar branco dos deuses'
  res[4].items[0].u.should.equal 'pote'
  res[4].extras.should.deep.equal [{desc: 'frete', value: 5000}, {desc: 'diferença', value: 662600}]
  res[4].total.should.equal 1000000
  res[5].should.deep.equal {kind: 'saída/conta', value: 2000, desc: 'luz'}
catch e
  console.log JSON.stringify res, null, 2
  console.log e
  throw e
