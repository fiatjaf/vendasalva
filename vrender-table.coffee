{table, thead, tr, th, tbody, td} = require 'virtual-elements'

module.exports = (tableDefinition) ->
  {data, columns, style} = tableDefinition

  (table className: 'table table-bordered table-hover table-stripped',
    (thead {},
      (tr {className: style},
        (th {},
          col
        ) for col in columns
      )
    )
    (tbody {},
      (tr {attributes: {title: row['_title']} if '_title' of row},
        (td {},
          "#{row[col]}" or ''
        ) for col in columns
      ) for row in data
    )
  )

