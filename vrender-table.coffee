{table, thead, tr, th, tbody, td} = require 'virtual-elements'

module.exports = (tableDefinition) ->
  {data, columns, style} = tableDefinition

  if not Array.isArray data[0]
    newdata = []
    for row, rowIndex in data
      newrow = []
      for k in columns
        newrow.push row[k] or if k == '#' then rowIndex+1 else ''
      newdata.push newrow
    data = newdata

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
          "#{point}" or ''
        ) for point in row
      ) for row in data
    )
  )

