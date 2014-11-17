fs       = require 'fs'
path     = require 'path'
spawn    = require('child_process').spawn

for file in fs.readdirSync path.resolve(__dirname, 'tests')
  if file[0] == '.' then continue

  ((test) ->
    p = spawn 'coffee', [path.resolve(__dirname, 'tests', test)]
    p.stdout.setEncoding 'utf8'
    p.stdout.on 'data', (data) -> console.log test + ':\n' + data.toString()
    p.stderr.setEncoding 'utf8'
    p.stderr.on 'data', (data) -> console.log test + ':\n' + data.toString()
    p.on 'close', (code) -> console.log if code == 0 then "#{test} succeeded." else "#{test} exited with code #{code}"
  )(file)
