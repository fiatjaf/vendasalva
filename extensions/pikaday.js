define(['../modules/pikaday', 'moment'], function (Pikaday, moment) {
  return {
    initialize: function (app) {
      app.sandbox.fieldPikaday = function (field) {
        var picker = new Pikaday({
          field: field,
          firstDay: 0,
          format: 'YYYY-MM-DD',
          i18n: {
            previousMonth: 'Mês anterior', 
            nextMonth: 'Próximo mês',
            months: ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
                     'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
            weekdays: ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'],
            weekdaysShort: ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb']
          },
          onSelect: function () {
            field.value = moment(picker.getDate()).format('YYYY-MM-DD')
          }
        })
        picker.setDate(moment().toDate())
        return picker
      }
    }
  }
})
