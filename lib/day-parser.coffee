yaml = require 'js-yaml'

exports = {}
module.exports = exports

exports.parser = (input) ->
  lines = input.split('\n')
  sections =
    notes: []

  for line in lines
    if line == ''
      key = null
    else if key == null
      key = line.split(':')[0].trim()
      sections[key] = []
      parse = parsers[key]
    else if key
      sections[key].push parse line

parsers = {}
parsers.vendas = (line) ->
  comma = line.split(',')
  if comma.length > 1
    for 

parsers.perdeu = parsers.vendas
parsers.retiradas = yaml.load
