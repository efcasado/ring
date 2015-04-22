###========================================================================
### File: Makefile
###
### Make file used to build the project and run the tests.
###
###
### You can customize the test by overiding the following options:
###
###   - NPROCS:   Number of processes in the ring (defaults to 1000)
###   - NREPS:    Number of times the message will be circulated over the
###               ring (defaults to 1)
###   - MSG_SIZE: Size of the message in bytes (defaults to 1024)
###   - MSG_TYPE: Binary (bin) or string (str) (defaults to bin)
###
### The results of the test are in microseconds.
###
###
### Author: Enrique Fernandez <efcasado@gmail.com>
###
###-- LICENSE -------------------------------------------------------------
### The MIT License (MIT)
###
### Copyright (c) 2015 Enrique Fernandez
###
### Permission is hereby granted, free of charge, to any person obtaining
### a copy of this software and associated documentation files (the
### "Software"), to deal in the Software without restriction, including
### without limitation the rights to use, copy, modify, merge, publish,
### distribute, sublicense, and/or sell copies of the Software,
### and to permit persons to whom the Software is furnished to do so,
### subject to the following conditions:
###
### The above copyright notice and this permission notice shall be included
### in all copies or substantial portions of the Software.
###
### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
### EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
### MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
### IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
### CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
### TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
### SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###========================================================================
.PHONY: all compile clean

## Settings
##=========================================================================
SRC_DIR   := src
BIN_DIR   := ebin
SRC_FILES := $(shell find $(SRC_DIR) -type f -name *.erl)
BIN_FILES := $(patsubst $(SRC_DIR)/%.erl,$(BIN_DIR)/%.beam,$(SRC_FILES))

ERLC      ?= $(shell which erlc)
ERLC_OPTS ?= -o $(BIN_DIR)
ERL       ?= $(shell which erl)
ERL_OPTS  ?= -noshell -pa $(BIN_DIR)

NPROCS    ?= 1000
NREPS     ?= 1
MSG_SIZE  ?= 1024 # in bytes
MSG_TYPE  ?= bin

define ringrun
    $(ERL) $(ERL_OPTS) -eval             " \
Result = ring:run($(1),$(2),$(3),$(4)),    \
io:format(\"~p~n\", [Result]),             \
halt(0)." | sed 's/{\(.*\),\(.*\)}/Avg. Latency: \1us, Total Time: \2us/g'
endef

## Targets
##=========================================================================
all: compile

compile: $(BIN_DIR) $(BIN_FILES)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

ebin/%.beam: src/%.erl
	$(ERLC) $(ERLC_OPTS) $<

test: compile
	@$(call ringrun,$(NPROCS),$(MSG_SIZE),$(MSG_TYPE),$(NREPS))

clean: ; rm -rf $(BIN_DIR)
