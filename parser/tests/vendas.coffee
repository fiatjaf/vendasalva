PEG      = require 'pegjs'
fs       = require 'fs'
path     = require 'path'
should   = require('chai').should()

parser = PEG.buildParser fs.readFileSync path.resolve(__dirname, '../dia.peg'), encoding: 'utf-8'

test = '''
2 pacotes de 1kg de farinha de arroz urbano: R$ 24,50
 1 garrafa de 500ml de vinagre de maçã jatobá : R$ 14
 2 sacos de 2 kg de soja: 7
 2 latas 500ml de pimenta: R$ 20

 saquinho de castanha de caju: 2,20

2 pacotes de 1kg de farinha de arroz urbano: R$ 24,50
banana, 2kg: R$ 20

 leite: R$ 3

 (banana 2,00 -- não pagou, homem do correio)

bolo de banana, 1kg: 4,80

1 pacote de uvas: R$ 4,50
2kg de uvas :40 reais
R$ 4: cacau-em-pó, 400g

soja orgânica, 12 pct: 8 reais

1 banana: 20 centavos

1kg açúcar mascavo: R$ 13,20
'''

res = parser.parse test

try
  res[0].u.should.equal 'pacote/1kg'
  res[0].item.should.equal 'farinha de arroz urbano'

  res[1].item.should.equal 'vinagre de maçã jatobá'
  res[1].u.should.equal 'garrafa/500ml'
  res[1].q.should.equal 1
  res[1].value.should.equal 1400

  res[2].u.should.equal 'saco/2kg'
  res[2].value.should.equal 700

  res[3].u.should.equal 'lata/500ml'
  res[3].q.should.equal 2

  res[4].u.should.equal 'saco'
  res[4].q.should.equal 1

  res[5].item.should.equal 'farinha de arroz urbano'

  res[6].item.should.equal 'banana'
  res[6].q.should.equal 2
  res[6].u.should.equal 'kg'

  res[7].u.should.equal 'u'
  res[7].q.should.equal 1
  res[7].value.should.equal 300

  #res[8].value.should.equal 200
  #res[8].pago.should.equal false
  #res[8].comment.should.equal 'não pagou, homem do correio'
  #res[8].u.should.equal 'u'
  #res[8].q.should.equal 1

  res[9].item.should.equal 'bolo de banana'
  res[9].q.should.equal 1
  res[9].u.should.equal 'kg'

  res[10].u.should.equal 'pacote'

  res[11].value.should.equal 4000
  res[11].item.should.equal 'uvas'
  res[11].q.should.equal 2

  res[12].item.should.equal 'cacau-em-pó'
  res[12].value.should.equal 400
  res[12].u.should.equal 'kg'
  res[12].q.should.equal 0.4

  res[13].q.should.equal 12
  res[13].value.should.equal 800

  res[14].value.should.equal 20
  res[14].item.should.equal 'banana'

  res[15].u.should.equal 'kg'
  res[15].item.should.equal 'açúcar mascavo'
  
catch e
  console.log JSON.stringify res, null, 2
  console.log e
  throw e
