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
.PHONY: all compile clean $(BENCHMARKS)

## Settings
##=========================================================================
SRC_DIR   := src
BIN_DIR   := ebin
RES_DIR   := results
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


## Functions
##=========================================================================
define ringrun
	$(eval TEST_RESULT := $(shell $(ERL) $(ERL_OPTS) -eval " \
Result = ring:run($(1),$(2),$(3),$(4)),                      \
io:format(\"~p~n\", [Result]),                               \
halt(0)."))
endef

define avg_latency
$(shell echo $1 | sed 's/{\(.*\),.*}/\1/g' | xargs echo)
endef

define tot_time
$(shell echo $1 | sed 's/{.*,\(.*\)}/\1/g' | xargs echo)
endef


## Targets
##=========================================================================
all: compile

compile: $(BIN_DIR) $(BIN_FILES)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(RES_DIR):
	mkdir -p $(RES_DIR)

ebin/%.beam: src/%.erl
	$(ERLC) $(ERLC_OPTS) $<

test: clean compile
	@$(call ringrun,$(NPROCS),$(MSG_SIZE),$(MSG_TYPE),$(NREPS))
	@echo '$(TEST_RESULT)' | sed 's/{\(.*\),\(.*\)}/Avg. Latency: \1us, Total Time: \2us/g'

MSG_SIZES  := 1 2 8 16 32 64 128 256 512 1024 # Message sizes (in bytes)
BENCHMARKS := $(patsubst %,benchmark-%, $(MSG_SIZES))
benchmark: clean compile $(RES_DIR) $(BENCHMARKS)
	scripts/plot "Average IPC Latency" avg-latency.png *_avg-latency.dat
	scripts/plot "Total Time" tot-time.png *_tot-time.dat

MSG_TYPES := bin str
NUM_PROCS := 1 2 8 16 32 64 128 256 512 1024 2048 4096 8192 16384
benchmark-%:
	@$(foreach t,$(MSG_TYPES), $(foreach p,$(NUM_PROCS), $(MAKE) test-$*_$(t)_$(p);))
	scripts/plot "Average IPC Latency" $*-bytes_avg-latency.png $**_avg-latency.dat
	scripts/plot "Total Time" $*-bytes_tot-time.png $**_tot-time.dat

test-%:
	$(eval TEST_ARGS     := $(shell echo $* | tr _ " "))
	$(eval TEST_MSG_SIZE := $(word 1, $(TEST_ARGS)))
	$(eval TEST_MSG_TYPE := $(word 2, $(TEST_ARGS)))
	$(eval TEST_NPROCS   := $(word 3, $(TEST_ARGS)))
	$(eval AVGLAT_FILE   := $(RES_DIR)/$(TEST_MSG_SIZE)-$(TEST_MSG_TYPE)_avg-latency.dat)
	$(eval TOTTIM_FILE   := $(RES_DIR)/$(TEST_MSG_SIZE)-$(TEST_MSG_TYPE)_tot-time.dat)
	@$(call ringrun,$(TEST_NPROCS),$(TEST_MSG_SIZE),$(TEST_MSG_TYPE),1)
	@echo "$(TEST_NPROCS)\t$(call avg_latency,'$(TEST_RESULT)')" >> $(AVGLAT_FILE)
	@echo "$(TEST_NPROCS)\t$(call tot_time,'$(TEST_RESULT)')" >> $(TOTTIM_FILE);

clean:
	rm -rf $(BIN_DIR)
	rm -rf $(RES_DIR)
	rm -f *.dump
	rm -f *.png
