# See MIT-LICENSE for licensing information.

# Variables definitions:
#  variable definition ecursively expanded when the variable is used,
#  not when it's declared

REBAR = `which rebar || echo ./rebar`
REBAR_SKIP_DEPS = skip_deps=true

DIALYZER = dialyzer
DIALYZER_WARNINGS = -Wunmatched_returns -Werror_handling \
	-Wrace_conditions -Wunderspecs
DIALYZER_APPS = --apps kernel stdlib sasl erts ssl \
	tools
DIALYZER_OUTPUT = .erlang_tools_dialyzer.plt

#  conditional variable definition, assign only if not yet assigned.
ERL ?= erl

#  variable definition expanded when it's declared
APP := erlang_tools

# Makefile targets format:
#
# 	target: dependencies
# 	[tab] system command

# Tells to make that deps is not a file/directory
.PHONY: deps

# Compiles erlang sources
all: deps
	@$(REBAR) compile
	ln -f ~/.$(APP)/.erlang ~/.erlang

# Cleans all files
clean:
	@$(REBAR) clean

# Pulls all dependencies
deps:
	@$(REBAR) get-deps

# Removes whole dependencies
distclean:
	@$(REBAR) delete-deps

# Generates documentation
doc:
	@$(REBAR) doc skip_deps=true

# Runs eunit tests
eunit:
	@$(REBAR) $(REBAR_SKIP_DEPS) eunit

# Runs ct tests
ct:
	@$(REBAR) $(REBAR_SKIP_DEPS) ct

# Runs all tests clean
test: clean deps all eunit #ct

# Generates plt file for project
build_plt: all
	@$(DIALYZER) --build_plt --output_plt $(DIALYZER_OUTPUT) \
		$(DIALYZER_APPS) #./deps/*

# Examines project using builded plt
release: all test
	@$(DIALYZER) --src src --plt $(DIALYZER_OUTPUT) \
		$(DIALYZER_WARNINGS)
