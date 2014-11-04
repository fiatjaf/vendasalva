PEG = require 'pegjs'
fs = require 'fs'

parser = PEG.buildParser fs.readFileSync 'dia.peg', {encoding: 'utf-8'}

console.log JSON.stringify parser.parse fs.readFileSync 'test.txt', {encoding: 'utf-8'}
