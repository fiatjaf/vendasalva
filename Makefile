all:
	make jison
	make design-doc
	make js
	make css

run:
	make all
	python -m SimpleHTTPServer 3000

js:
	./node_modules/.bin/browserify -t coffeeify -t brfs main.coffee > assets/app.js

css:
	./node_modules/.bin/lessc style.less > assets/style.css

design-doc:
	python compile_ddoc.py ddoc > ddoc.json

jison:
	./node_modules/.bin/jison parser/day-parser.y
	mv day-parser.js parser/
	cp parser/day-parser.js ddoc/views/
