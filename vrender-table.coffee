{table, thead, tr, th, tbody, td} = require 'virtual-elements'

module.exports = (tableDefinition) ->
  {data, columns, className} = tableDefinition

  (table className: className,
    (thead {},
      (tr {},
        (th {},
          col
        ) for col in columns
      )
    )
    (tbody {},
      (tr {},
        (td {},
          "#{row[col]}" or ''
        ) for col in columns
      ) for row in data
    )
  )

