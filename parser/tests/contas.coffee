PEG      = require 'pegjs'
fs       = require 'fs'
path     = require 'path'
should   = require('chai').should()

parser = PEG.buildParser fs.readFileSync path.resolve(__dirname, '../dia.peg'), encoding: 'utf-8'

test = '''
saída para conta de luz: 40
conta de água: R$ 20
taxa de incêndio: R$ 25
boleto solarius: R$ 290
saída p/ pagamento de funcionária: R$ 500
PAG TERRA FRUTA : r$ 20,00
'''

res = parser.parse test

res[0].should.deep.equal {kind: 'saída/conta', value: 4000, desc: 'luz'}
res[1].should.deep.equal {kind: 'conta', value: 2000, desc: 'água'}
res[2].should.deep.equal {kind: 'conta', value: 2500, desc: 'incêndio'}
res[3].should.deep.equal {kind: 'conta', value: 29000, desc: 'solarius'}
res[4].should.deep.equal {kind: 'saída/conta', value: 50000, desc: 'funcionária'}
res[5].should.deep.equal {kind: 'conta', value: 2000, desc: 'terra fruta'}
