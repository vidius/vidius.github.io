BROWSERIFY = node_modules/.bin/browserify
COFFEE = node_modules/.bin/coffee

all : lib/bootlogo.js lib/gfx.js

clean :
	rm -f lib/*.js
	rm -f lib/*.map

lib/%.js : src/%.coffee
	@echo "[COFFEE] $< -> $@"
	@mkdir -p lib
	@$(COFFEE) -jo $@ --source-map-file $(@:.js=.map) -i $<

.PHONY : all clean
