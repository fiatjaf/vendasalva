#!/usr/bin/python

import sys
import json
import requests
import subprocess

def parser():
    subprocess.call(['./node_modules/.bin/pegjs', 'parser/dia.peg'])
    subprocess.call(['./node_modules/.bin/pegjs', '-e', 'parser', 'parser/dia.peg', 'parser/parser.js'])
    with open('parser/parser.js') as f:
        parser = f.read()
    mapfun = subprocess.check_output(['coffee', '--print', '--bare', '--compile', 'ddoc/views/main/map.coffee'])
    mapfun = mapfun.replace('~ import parser ~', parser)
    with open('ddoc/views/main/map.js', 'w') as f:
        f.write(mapfun)

def grammar():
    with open('parser/dia.peg') as s:
        grammar = s.read()
    with open('ddoc.json') as d:
        ddoc = json.load(d)

    ddoc['grammar'] = grammar
    with open('ddoc.json', 'w') as t:
        t.write(json.dumps(ddoc))

def ddoc():
    filterfun = subprocess.check_output(['coffee', '--print', '--bare', '--compile', 'ddoc/filters/ddocs-only.coffee'])
    with open('ddoc/filters/ddocs-only.js', 'w') as f:
        f.write(filterfun)

    from couchapp.localdoc import document
    with open('ddoc.json', 'w') as f:
        f.write(json.dumps(document('ddoc').doc()))

def upload_ddoc():
    ddoc = json.load(open('ddoc.json'))
    id = '_design/' + ddoc['_id'].split('/')[1]
    rev = requests.head(sys.argv[2] + '/' + id).headers['Etag']
    ddoc['_rev'] = rev[1:-1]
    requests.put(sys.argv[2] + '/' + id, headers={'content-type': 'application/json'}, data=json.dumps(ddoc)).text

def app():
    js = subprocess.check_output(['./node_modules/.bin/browserify', '-t', 'coffeeify', '-t', 'brfs', 'main.coffee'])
    with open('assets/app.js', 'w') as f:
        f.write(js)
    css = subprocess.check_output(['./node_modules/.bin/lessc', 'style.less'])
    with open('assets/style.css', 'w') as f:
        f.write(css)

def run():
    import SimpleHTTPServer
    import SocketServer
    print 'serving at port 3000'
    SocketServer.TCPServer(("", 3000), SimpleHTTPServer.SimpleHTTPRequestHandler).serve_forever()

if len(sys.argv) == 1:
    app()
elif sys.argv[1] == 'parser':
    parser()
elif sys.argv[1] == 'ddoc':
    ddoc()
elif sys.argv[1] == 'upload-ddoc':
    parser()
    grammar()
    ddoc()
    upload_ddoc()
elif sys.argv[1] == 'run':
    app()
    run()
