date         = require 'date-extended'

StateFactory = require './state-factory.coffee'

module.exports = new StateFactory
  activeTab: 'input'
  modalOpened: null
  loggedAs: null
  forcedSearchValue: ''

  input:
    usingLocalCache: false
    activeDay: date.format(new Date, 'yyyy-MM-dd')
    rawInput: ''
    parsedInput: null

  resumo:
    receita:
      months: []
    top:
      weeks: []
      overall: []

  searchresults:
    results: []

  dias:
    list: []
