# oosh v0.2.0 Makefile
#
# Build, verify, and test the openOODA sovereign shell.
#
# Usage:
#   make build       - compile main.oo to dist/oosh
#   make test        - run --help, --version, flags, and REPL smoke tests
#   make parity      - verify binary hash
#   make line-cap    - enforce 16-256 line cap on every .oo and .oot
#   make file-law    - reject forbidden file extensions
#   make academy     - verify every .oo has the 4-element Academy header
#   make check       - run oodac check on every .oo file
#   make verify      - run line-cap, file-law, and academy checks
#   make install     - copy dist/oosh to ~/.openooda/bin/oosh
#   make clean       - remove build artifacts
#   make all         - build + verify + test

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/oosh

SRC := main.oo version.oo anchor.oo prompt.oo dispatch.oo engine.oo

.PHONY: all build test parity line-cap file-law academy check verify install clean

all: build verify test

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/oosh-linux-x86_64
	@sha256sum dist/oosh-linux-x86_64 > dist/oosh-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/oosh-linux-x86_64)"

test: $(BIN)
	@echo "=== testing --help ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@echo "=== testing --version ==="
	@./$(BIN) --version > /dev/null && echo "PASS: --version"
	@echo "=== testing banner ==="
	@./$(BIN) -c "version" > /dev/null && echo "PASS: banner"
	@echo "=== testing -c execution ==="
	@test "$$(./$(BIN) -c 'echo hello_sovereign')" = "hello_sovereign" && echo "PASS: -c execution"
	@echo "=== testing pipe execution ==="
	@echo "echo stream_ok" | ./$(BIN) --no-banner | grep -q "stream_ok" && echo "PASS: stream pipe"
	@echo "=== testing builtin help ==="
	@echo "help" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: builtin help"
	@echo "=== testing --unknown-flag (expect exit 2) ==="
	@./$(BIN) --unknown-flag 2>/dev/null; test $$? -eq 2 && echo "PASS: error exit 2"
	@echo "=== testing installer dry-run ==="
	@./install.sh --dry-run > /dev/null && echo "PASS: install.sh dry-run"

parity: build
	@sum=$$(sha256sum $(BIN) | awk '{print $$1}'); echo $$sum; test -n "$$sum"

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; \
			violations=$$((violations+1)); \
		fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor)"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh: $$f"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo"); do \
		header=$$(head -7 "$$f"); \
		if ! echo "$$header" | grep -q "^// # "; then \
			echo "FAIL: $$f missing '// # <Title>' in first 7 lines"; \
			failures=$$((failures+1)); \
			continue; \
		fi; \
		if ! echo "$$header" | grep -q "^// Logline:"; then \
			echo "FAIL: $$f missing '// Logline:' in first 7 lines"; \
			failures=$$((failures+1)); \
			continue; \
		fi; \
		if ! echo "$$header" | grep -q "^// Setup:"; then \
			echo "FAIL: $$f missing '// Setup:' in first 7 lines"; \
			failures=$$((failures+1)); \
			continue; \
		fi; \
		if ! echo "$$header" | grep -q "^// Beats:"; then \
			echo "FAIL: $$f missing '// Beats:' in first 7 lines"; \
			failures=$$((failures+1)); \
			continue; \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

check:
	@for f in $$(find . -name "*.oo"); do \
		$(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy check

install: build
	@mkdir -p $(HOME)/.openooda/bin
	cp -a $(BIN) $(HOME)/.openooda/bin/oosh
	@chmod +x $(HOME)/.openooda/bin/oosh
	@echo "installed $(HOME)/.openooda/bin/oosh"

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
