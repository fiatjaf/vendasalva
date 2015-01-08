PEG      = require 'pegjs'
fs       = require 'fs'
path     = require 'path'
should   = require('chai').should()

parser = PEG.buildParser fs.readFileSync path.resolve(__dirname, '../dia.peg'), encoding: 'utf-8'

test = '''
saldo inicial: 5,23

banana: 10

saldo parcial: 15,23

saldo: 17,00
'''

res = parser.parse test

try
  res[0].should.deep.equal {kind: 'saldo', value: 523, desc: 'inicial'}
  res[1].value.should.equal 1000
  res[2].should.deep.equal {kind: 'saldo', value: 1523, desc: 'parcial'}
  res[3].should.deep.equal {kind: 'saldo', value: 1700}
catch e
  console.log JSON.stringify res, null, 2
  console.log e
  throw e
