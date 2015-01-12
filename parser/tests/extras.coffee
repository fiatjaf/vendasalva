PEG      = require 'pegjs'
fs       = require 'fs'
path     = require 'path'
should   = require('chai').should()

parser = PEG.buildParser fs.readFileSync path.resolve(__dirname, '../dia.peg'), encoding: 'utf-8'

test = '''
1 pacote de farinha de trigo integral: 2,00 no cartao de credito
 litro de leite: R$ 3 de 3x no cartão
1 espinafre (desc): 2,50

1 pacote de uvas (meio velhas): R$ 4,50 fiado para beltrano
1 pacote de uvas: R$ 4,50 na conta de fulano (um crédito antigo que ele tinha)

saída pagamento sr.caxias: 20
'''

res = parser.parse test

try
  res.should.have.length 6

  res[0].pagamento.should.equal 'crédito'
  res[0].item.should.equal 'farinha de trigo integral'

  res[1].pagamento.should.equal 'cartão'
  res[1].x.should.equal 3

  res[2].note.should.equal 'desc'
  res[2].item.should.equal 'espinafre'
  res[2].value.should.equal 250

  res[3].value.should.equal 450
  should.equal res[3].pagamento, null
  res[3].note.should.equal 'meio velhas'
  res[3].cliente.should.equal 'beltrano'

  res[4].value.should.equal 450
  should.equal res[4].pagamento, null
  res[4].cliente.should.equal 'fulano'
  res[4].note.should.equal 'um crédito antigo que ele tinha'

  res[5].kind.should.equal 'saída/conta'
  res[5].desc.should.equal 'sr.caxias'
  res[5].value.should.equal 2000
  
catch e
  console.log JSON.stringify res, null, 2
  console.log e
  throw e
