date         = require 'date-extended'

StateFactory = require './state-factory.coffee'

module.exports = StateFactory
  activeTab: 'Input'
  parsedData:
    vendas: []
    compras: []
    contas: []
    comments: []
    caixa: [{desc: 'Vendas', value: 0}]
    receita: 0
  daysList: []
  searchResults: []
  forcedSearchValue: ''

  input:
    usingLocalCache: false
    activeDay: date.format(new Date, 'yyyy-MM-dd')
    rawInput: ''
    parsedInput: null
