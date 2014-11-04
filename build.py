#!/usr/bin/python

import sys
import json
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

def ddoc():
    from couchapp.localdoc import document
    with open('ddoc.json', 'w') as f:
        f.write(json.dumps(document('ddoc').doc()))

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
    parser()
    ddoc()
    app()
elif sys.argv[1] == 'parser':
    parser()
elif sys.argv[1] == 'ddoc':
    ddoc()
elif sys.argv[1] == 'app':
    app()
elif sys.argv[1] == 'run':
    parser()
    ddoc()
    app()
    run()
