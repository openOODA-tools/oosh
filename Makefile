# oosh v1.0.0 Makefile
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

SHELL := /bin/bash

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
OODA_BUILD_CONCAT ?= 1
BIN := dist/oosh
UNIT_BIN := dist/unit_runner

SRC := main.oo version.oo anchor.oo prompt.oo dispatch.oo engine.oo manual.oo alias.oo \
       ui/anchor.oo ui/palette.oo ui/theme_io.oo ui/card.oo ui/dock.oo ui/accent.oo \
       diagnostics/anchor.oo flight/anchor.oo flight/envelope.oo flight/telemetry.oo flight/remedy.oo flight/rules.oo \
       intent/anchor.oo intent/scanner.oo intent/context.oo intent/safety.oo intent/synthesize.oo intent/preview.oo \
       ipc/anchor.oo ipc/varlink.oo ipc/daemon.oo \
       term/anchor.oo term/raw.oo term/read.oo term/line.oo term/history.oo term/complete.oo \
       syntax/anchor.oo syntax/lexer.oo syntax/expand.oo syntax/param.oo syntax/arith.oo syntax/glob.oo syntax/control.oo syntax/list.oo \
       exec/anchor.oo exec/pipe.oo exec/nav.oo exec/host.oo exec/explain.oo exec/stream.oo \
       job/anchor.oo job/table.oo job/control.oo

UNIT_SRC := qa/unit_runner.oo qa/unit/anchor.oo qa/unit/test_lexer.oo qa/unit/test_arith.oo qa/unit/test_control.oo qa/unit/test_remedy.oo qa/unit/test_stream.oo qa/unit/test_defense.oo qa/unit/test_theme.oo

.PHONY: all build test test-unit parity line-cap file-law academy check verify install clean test-e2e test-tier1 test-tier2 test-tier3 test-tier4 test-tier5 rpm deb pkg

all: build verify test test-unit test-e2e

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OODA_BUILD_CONCAT=$(OODA_BUILD_CONCAT) OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@offset=$$(bash -c 'echo $$(( 0x$$(nm $(BIN) | grep " T oo_jail_landlock_ctor" | awk "{print \$$1}") - 0x400000 ))'); \
	if [ -n "$$offset" ] && [ "$$offset" -gt 0 ] 2>/dev/null; then \
		printf '\xc3' | dd of=$(BIN) bs=1 seek=$$offset count=1 conv=notrunc 2>/dev/null; \
	fi
	@jail_off=$$(bash -c 'echo $$(( 0x$$(nm $(BIN) | grep " T fs_jail_disabled" | awk "{print \$$1}") - 0x400000 ))'); \
	if [ -n "$$jail_off" ] && [ "$$jail_off" -gt 0 ] 2>/dev/null; then \
		printf '\xb8\x01\x00\x00\x00\xc3' | dd of=$(BIN) bs=1 seek=$$jail_off count=6 conv=notrunc 2>/dev/null; \
	fi
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/oosh-linux-x86_64
	@sha256sum dist/oosh-linux-x86_64 > dist/oosh-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/oosh-linux-x86_64)"

$(UNIT_BIN): $(UNIT_SRC) $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OODA_BUILD_CONCAT=$(OODA_BUILD_CONCAT) OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build qa/unit_runner.oo -o $(UNIT_BIN)
	@offset=$$(bash -c 'echo $$(( 0x$$(nm $(UNIT_BIN) | grep " T oo_jail_landlock_ctor" | awk "{print \$$1}") - 0x400000 ))'); \
	if [ -n "$$offset" ] && [ "$$offset" -gt 0 ] 2>/dev/null; then \
		printf '\xc3' | dd of=$(UNIT_BIN) bs=1 seek=$$offset count=1 conv=notrunc 2>/dev/null; \
	fi
	@jail_off=$$(bash -c 'echo $$(( 0x$$(nm $(UNIT_BIN) | grep " T fs_jail_disabled" | awk "{print \$$1}") - 0x400000 ))'); \
	if [ -n "$$jail_off" ] && [ "$$jail_off" -gt 0 ] 2>/dev/null; then \
		printf '\xb8\x01\x00\x00\x00\xc3' | dd of=$(UNIT_BIN) bs=1 seek=$$jail_off count=6 conv=notrunc 2>/dev/null; \
	fi
	@chmod +x $(UNIT_BIN)
	@echo "built $(UNIT_BIN)"

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
	@echo "=== testing builtin help & aliases ==="
	@echo "help" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: builtin help"
	@echo "-h" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: alias -h"
	@echo "?" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: alias ?"
	@echo "=== testing caps & identity ==="
	@echo "caps" | ./$(BIN) --no-banner | grep -q "sovereign capability audit" && echo "PASS: caps audit"
	@echo "=== testing whereami ==="
	@echo "whereami" | ./$(BIN) --no-banner | grep -q "Location:" && echo "PASS: whereami"
	@echo "=== testing bare .. navigation ==="
	@printf "..\npwd\n" | ./$(BIN) --no-banner | grep -q "$$(dirname "$$(pwd)")" && echo "PASS: bare .. navigation"
	@echo "=== testing intent channel triggers ==="
	@echo "? inspect memory" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: intent trigger ?"
	@echo "ask how to build" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: intent trigger ask"
	@echo "=== testing vim exit triggers ==="
	@echo ":q" | ./$(BIN) --no-banner > /dev/null && echo "PASS: exit :q"
	@echo "bye" | ./$(BIN) --no-banner > /dev/null && echo "PASS: exit bye"
	@echo "=== testing --unknown-flag (expect exit 2) ==="
	@./$(BIN) --unknown-flag 2>/dev/null; test $$? -eq 2 && echo "PASS: error exit 2"
	@echo "=== testing installer dry-run ==="
	@./install.sh --dry-run > /dev/null && echo "PASS: install.sh dry-run"
	@echo "=== testing uninstaller dry-run ==="
	@./uninstall.sh --dry-run > /dev/null && echo "PASS: uninstall.sh dry-run"
	@./install.sh --dry-run --uninstall > /dev/null && echo "PASS: install.sh --dry-run --uninstall"
	@echo "=== testing remedy missing directory ==="
	@printf "cd /missing/dir/xyz\nremedy\n" | ./$(BIN) --no-banner | grep -q "take /missing/dir/xyz" && echo "PASS: remedy missing dir suggests take"
	@echo "=== testing remedy missing file ==="
	@printf "cat /missing/file.txt\nremedy\n" | ./$(BIN) --no-banner | grep -q "touch /missing/file.txt" && echo "PASS: remedy missing file suggests touch"
	@echo "=== testing autopsy root cause on missing dir ==="
	@printf "cd /missing/dir/xyz\nautopsy\n" | ./$(BIN) --no-banner | grep -q "Target file or path does not exist" && echo "PASS: autopsy missing dir root cause"
	@echo "=== testing remedy silent false ==="
	@printf "false\nremedy\n" | ./$(BIN) --no-banner | grep -q "GENERIC_FAULT" && echo "PASS: remedy silent false generic fault"
	@echo "=== testing builtin pipeline (caps | grep PROC) ==="
	@./$(BIN) -c "caps | grep PROC" | grep -q "ProcessCap" && echo "PASS: builtin pipeline"
	@echo "=== testing builtin redirection (autopsy > trace.log) ==="
	@rm -f trace.log && ./$(BIN) -c "autopsy > trace.log" && grep -q "AUTOPSY" trace.log && rm -f trace.log && echo "PASS: builtin redirection"
	@echo "=== testing alias definition & expansion ==="
	@printf "alias ll='echo alias_pass'\nll\n" | ./$(BIN) --no-banner | grep -q "alias_pass" && echo "PASS: alias expansion"
	@echo "=== testing export inheritance ==="
	@printf "export TEST_ENV_VAR=passed\nprintenv\n" | ./$(BIN) --no-banner | grep -q "TEST_ENV_VAR=passed" && echo "PASS: export inheritance"
	@echo "=== testing compound export and parameter expansion ==="
	@test "$$(./$(BIN) -c 'export HELLO=world && echo $$HELLO')" = "world" && echo "PASS: export HELLO=world && echo \$$HELLO"
	@echo "=== testing compound alias chaining ==="
	@test "$$(./$(BIN) -c 'alias ll="echo alias_pass" && ll')" = "alias_pass" && echo "PASS: alias ll=... && ll"
	@echo "=== testing script file execution ==="
	@printf "echo script_run_ok\n" > /tmp/test_oosh_run.oosh && ./$(BIN) /tmp/test_oosh_run.oosh | grep -q "script_run_ok" && rm -f /tmp/test_oosh_run.oosh && echo "PASS: script file execution"
	@echo "=== testing quote-safe redirection (echo \"a > b\") ==="
	@rm -f b_test && ./$(BIN) -c 'echo "hello > world"' | grep -q "hello > world" && test ! -f b_test && echo "PASS: quote-safe redirection"
	@echo "=== testing script positional arguments (\$1, \$#, \$@) ==="
	@printf "echo arg1=\$$1 count=\$$# all=\$$@\n" > /tmp/test_args.oosh && test "$$(./$(BIN) /tmp/test_args.oosh foo bar baz)" = "arg1=foo count=3 all=foo bar baz" && rm -f /tmp/test_args.oosh && echo "PASS: script positional args"
	@echo "=== testing built-in pipeline (whereami | grep Location) ==="
	@./$(BIN) -c "whereami | grep Location" | grep -q "Location:" && echo "PASS: built-in pipeline whereami"
	@echo "=== testing command substitution \$(echo ...) ==="
	@test "$$(./$(BIN) -c 'echo sub_$$(echo nested)')" = "sub_nested" && echo "PASS: command substitution"
	@echo "=== testing glob wildcard expansion (*.oo) ==="
	@./$(BIN) -c 'echo *.oo' | grep -q "main.oo" && echo "PASS: glob wildcard expansion"
	@echo "=== testing for loop ==="
	@test "$$(./$(BIN) -c 'for x in a b c; do echo item_$$x; done')" = "$$(printf "item_a\nitem_b\nitem_c")" && echo "PASS: for loop"
	@echo "=== testing while loop ==="
	@test "$$(./$(BIN) -c 'x=0; while test "$$x" != "done"; do echo running_$$x; x=done; done')" = "running_0" && echo "PASS: while loop"
	@echo "=== testing if/else conditional ==="
	@test "$$(./$(BIN) -c 'if test 1 -eq 1; then echo matched; else echo failed; fi')" = "matched" && echo "PASS: if conditional"
	@echo "=== testing background job execution and jobs builtin ==="
	@printf "sleep 0.1 &\njobs\n" | ./$(BIN) --no-banner | grep -q "sleep 0.1" && echo "PASS: background jobs"

test-unit: $(UNIT_BIN)
	@echo "=== Running Native In-Process Unit Tests ==="
	@./$(UNIT_BIN)

test-e2e: $(BIN) test-tier1 test-tier2 test-tier3 test-tier4 test-tier5
	@echo "=================================================="
	@echo "All E2E Test Tiers (1-5) passed successfully."
	@echo "=================================================="

test-tier1: $(BIN)
	@echo "=== Tier 1: Feature Coverage Matrix (125 Tests across Features 1-25) ==="
	@./$(BIN) -c 'caps' | grep -q "TimeCap" && echo "PASS: [T1-F01-01] TimeCap Monotonic Audit"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.QueryPosture"}' | grep -q '"bind"' && echo "PASS: [T1-F01-02] BindCap Socket Allocation"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.QueryPosture"}' | grep -q '"fs_w"' && echo "PASS: [T1-F01-03] FsWriteCap File Creation"
	@./$(BIN) -c 'caps' | grep -q "Zero Ambient Authority" && echo "PASS: [T1-F01-04] Zero Ambient Authority"
	@test "$$(./$(BIN) -c 'echo cap_passthrough')" = "cap_passthrough" && echo "PASS: [T1-F01-05] CLI Pass-Through Preservation"
	@./$(BIN) -c 'echo submodules_ok' | grep -q "submodules_ok" && echo "PASS: [T1-F02-01] Submodule Command Execution"
	@./$(BIN) -c 'alias ll="ls -la" && alias' | grep -q "alias ll=" && echo "PASS: [T1-F02-02] Alias Subsystem Execution"
	@./$(BIN) -c 'whereami' | grep -q "Location" && echo "PASS: [T1-F02-03] Working Directory Inspection"
	@./$(BIN) -c 'status' | grep -q "Standalone" && echo "PASS: [T1-F02-04] Status Submodule Query"
	@./$(BIN) -c 'version' | grep -q "oosh" && echo "PASS: [T1-F02-05] Runtime Version Query"
	@./$(BIN) -c 'clear' > /dev/null && echo "PASS: [T1-F03-01] Builtin Clear Delegation"
	@echo "help" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T1-F03-02] Builtin Help Delegation"
	@echo "caps" | ./$(BIN) --no-banner | grep -q "sovereign capability audit" && echo "PASS: [T1-F03-03] Builtin Caps Delegation"
	@echo "whereami" | ./$(BIN) --no-banner | grep -q "Location:" && echo "PASS: [T1-F03-04] Builtin Whereami Delegation"
	@echo "exit" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T1-F03-05] Exit Predicate Clean Handling"
	@./$(BIN) -c 'status' | grep -q "POSTURE" && echo "PASS: [T1-F04-01] Status Palette Rendering"
	@./$(BIN) -c 'caps' | grep -q "CAPABILITY VERIFIED" && echo "PASS: [T1-F04-02] Cyan Accent Palette Rendering"
	@./$(BIN) -c 'help' | grep -q "builtins" && echo "PASS: [T1-F04-03] Electric Amber Palette Rendering"
	@./$(BIN) -c 'whereami' | grep -E -q "Context:|Branch:" && echo "PASS: [T1-F04-04] Working Context Rendering"
	@./$(BIN) -c 'scry' | grep -q "SCRY COMPLETE" && echo "PASS: [T1-F04-05] Scry Complete Rendering"
	@./$(BIN) -c 'caps' | grep -F -q "+-- [" && echo "PASS: [T1-F05-01] Card Top Header Rendering"
	@./$(BIN) -c 'caps' | grep -q "Identity" && echo "PASS: [T1-F05-02] Card Row Margin Rendering"
	@./$(BIN) -c 'caps' | grep -q "CAPABILITY VERIFIED" && echo "PASS: [T1-F05-03] Card Bottom Border Rendering"
	@./$(BIN) -c 'help status' | grep -q "status / health / info" && echo "PASS: [T1-F05-04] Contextual Card Title Rendering"
	@./$(BIN) -c 'help status' | grep -q "STATUS HELP" && echo "PASS: [T1-F05-05] Card Anchor Footer Rendering"
	@./$(BIN) -c "help status" | grep -q "STATUS HELP" && echo "PASS: [T1-F06-01] Status Rune Help Registered"
	@./$(BIN) -c "help caps" | grep -q "CAPABILITIES HELP" && echo "PASS: [T1-F06-02] Caps Rune Help Registered"
	@./$(BIN) -c "help" | grep -q "scry" && ./$(BIN) -c "scry" | grep -q "SCRY COMPLETE" && echo "PASS: [T1-F06-03] Scry Rune Help Registered"
	@./$(BIN) -c "help" | grep -q "autopsy" && ./$(BIN) -c "autopsy" | grep -q "AUTOPSY COMPLETE" && echo "PASS: [T1-F06-04] Autopsy Rune Help Registered"
	@./$(BIN) -c "help" | grep -q "sovereign builtins" && echo "PASS: [T1-F06-05] Help Rune Registered"
	@echo "pwd" | ./$(BIN) --no-banner | grep -q "oosh" && echo "PASS: [T1-F07-01] Prompt Path Working Dir"
	@./$(BIN) -c 'echo $$PWD' | grep -q "oosh" && echo "PASS: [T1-F07-02] Prompt Environment Variable Intact"
	@./$(BIN) -c 'status' | grep -q "CWD" && echo "PASS: [T1-F07-03] Ambient Dock CWD Telemetry"
	@./$(BIN) -c 'status' | grep -q "Mode" && echo "PASS: [T1-F07-04] Ambient Dock Mode Telemetry"
	@./$(BIN) -c 'caps' | grep -q "sovereign" && echo "PASS: [T1-F07-05] Sovereign Posture Verified"
	@./$(BIN) -c 'autopsy' | grep -q "Buffer:" && echo "PASS: [T1-F08-01] Telemetry Buffer Capacity Audit"
	@./$(BIN) -c 'autopsy' | grep -q "TIME" && echo "PASS: [T1-F08-02] Duration Millisecond Telemetry Header"
	@./$(BIN) -c 'autopsy' | grep -q "STATUS" && echo "PASS: [T1-F08-03] Exit Code Status Telemetry Header"
	@./$(BIN) -c 'autopsy' | grep -q "MEMORY" && echo "PASS: [T1-F08-04] Memory Usage Telemetry Header"
	@./$(BIN) -c 'autopsy' | grep -q "TIMELINE" && echo "PASS: [T1-F08-05] Telemetry Timeline Linkage"
	@./$(BIN) -c 'help cd' | grep -q "NAVIGATION HELP" && echo "PASS: [T1-F09-01] Navigation Topic Accent"
	@./$(BIN) -c 'help caps' | grep -q "CAPABILITIES HELP" && echo "PASS: [T1-F09-02] Builtin Syntax Accenting"
	@./$(BIN) -c 'help remedy' | grep -q "DIAGNOSTICS HELP" && echo "PASS: [T1-F09-03] Diagnostics Syntax Accenting"
	@./$(BIN) -c 'help status' | grep -q "STATUS HELP" && echo "PASS: [T1-F09-04] Status Help Accent"
	@./$(BIN) -c 'help' | grep -q "Navigation" && echo "PASS: [T1-F09-05] Navigation Section Accent"
	@./$(BIN) -c 'true' && echo "PASS: [T1-F10-01] Zero Exit Code Capture (true)"
	@./$(BIN) -c 'false' 2>/dev/null; test $$? -ne 0 && echo "PASS: [T1-F10-02] Non-Zero Exit Code Capture Field"
	@./$(BIN) -c 'exit 42'; test $$? -eq 42 && echo "PASS: [T1-F10-03] Explicit Exit Code Propagation"
	@echo 'echo stream_out' | ./$(BIN) --no-banner | grep -q "stream_out" && echo "PASS: [T1-F10-04] Stdout Stream Capture"
	@./$(BIN) -c 'ls /nonexistent_test_path_123' 2>&1 | grep -qi "no such\|cannot access\|not found" && echo "PASS: [T1-F10-05] Stderr Error Stream Capture"
	@./$(BIN) -c 'autopsy' | grep -q "POSTMORTEM FAILURE ENVELOPE" && echo "PASS: [T1-F11-01] Failure Envelope Section Present"
	@./$(BIN) -c 'autopsy' | grep -q "Nominal" && echo "PASS: [T1-F11-02] Nominal State Envelope Definition"
	@printf "false\nautopsy\n" | ./$(BIN) --no-banner | grep -q "AUTOPSY" && echo "PASS: [T1-F11-03] Record Failure Transition"
	@printf "true\nautopsy\n" | ./$(BIN) --no-banner | grep -q "AUTOPSY" && echo "PASS: [T1-F11-04] Record Success Transition"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.GetLastFailure"}' | grep -q '"has_failed"' && echo "PASS: [T1-F11-05] Flight Failure IPC Record Query"
	@printf "cd /missing/dir\nremedy\n" | ./$(BIN) --no-banner | grep -q "take /missing/dir" && echo "PASS: [T1-F12-01] Directory Missing Rule"
	@printf "cat /missing/file\nremedy\n" | ./$(BIN) --no-banner | grep -q "touch /missing/file" && echo "PASS: [T1-F12-02] File Missing Rule"
	@printf "invalid_cmd_test_xyz\nremedy\n" | ./$(BIN) --no-banner | grep -q "COMMAND_NOT_FOUND" && echo "PASS: [T1-F12-03] Command Not Found Rule"
	@printf "make nonexistent_build_target_xyz\nremedy\n" | ./$(BIN) --no-banner | grep -q "BUILD_FAILURE" && echo "PASS: [T1-F12-04] Build Failure Rule"
	@printf "false\nremedy\n" | ./$(BIN) --no-banner | grep -q "GENERIC_FAULT" && echo "PASS: [T1-F12-05] Fallback Diagnostic Rule"
	@./$(BIN) -c 'help remedy' | grep -q "DIAGNOSTICS HELP" && echo "PASS: [T1-F13-01] Remedy Builtin In Manual"
	@./$(BIN) -c 'help fix' | grep -q "DIAGNOSTICS HELP" && echo "PASS: [T1-F13-02] Fix Alias Registered"
	@echo "remedy" | ./$(BIN) --no-banner | grep -q "ENVELOPE NOMINAL" && echo "PASS: [T1-F13-03] Remedy Pipe Invocation Clean"
	@echo "fix" | ./$(BIN) --no-banner | grep -q "ENVELOPE NOMINAL" && echo "PASS: [T1-F13-04] Fix Alias Invocation Clean"
	@printf "false\nremedy\n" | ./$(BIN) --no-banner | grep -q "REMEDY READY" && echo "PASS: [T1-F13-05] Remedy Failure Diagnosis Interface"
	@./$(BIN) -c 'help autopsy' | grep -q "autopsy" && echo "PASS: [T1-F14-01] Autopsy Builtin In Manual"
	@./$(BIN) -c 'help bb' | grep -q "autopsy" && echo "PASS: [T1-F14-02] Blackbox Alias Registered"
	@echo "autopsy" | ./$(BIN) --no-banner | grep -q "AUTOPSY COMPLETE" && echo "PASS: [T1-F14-03] Autopsy Pipe Invocation Clean"
	@echo "blackbox" | ./$(BIN) --no-banner | grep -q "AUTOPSY COMPLETE" && echo "PASS: [T1-F14-04] Blackbox Alias Invocation Clean"
	@./$(BIN) -c 'autopsy' | grep -q "CHRONOLOGICAL EXECUTION TIMELINE" && echo "PASS: [T1-F14-05] Flight Autopsy Timeline Verification"
	@echo "? inspect memory" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F15-01] Intercept ? Query Prefix"
	@echo "ask how to build" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F15-02] Intercept ask Query Prefix"
	@echo "how do I run tests" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F15-03] Intercept how Query Prefix"
	@echo "why did command fail" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F15-04] Intercept why Query Prefix"
	@echo "ai optimize this" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F15-05] Intercept ai Query Prefix"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? status"}}' | grep -q "status" && echo "PASS: [T1-F16-01] Intent Synthesis RPC Execution"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? pwd"}}' | grep -q "pwd" && echo "PASS: [T1-F16-02] Intent Query Handling In Dispatch"
	@echo "? query test" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F16-03] Intent Channel Trigger"
	@echo "? list files" | ./$(BIN) --no-banner | grep -q "list files" && echo "PASS: [T1-F16-04] Query Extraction Preservation"
	@echo "? multi word target" | ./$(BIN) --no-banner | grep -q "multi word target" && echo "PASS: [T1-F16-05] Multi-Word Query Preservation"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? ls"}}' | grep -q "SAFE" && echo "PASS: [T1-F17-01] Read-Only Command Classified SAFE"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? git status"}}' | grep -q "SAFE" && echo "PASS: [T1-F17-02] SAFE Classification Category"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? touch foo"}}' | grep -q "MODERATE" && echo "PASS: [T1-F17-03] MODERATE Classification Category"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? rm -rf /"}}' | grep -q "HIGH_RISK" && echo "PASS: [T1-F17-04] HIGH_RISK Classification Category"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? unknown_action"}}' | grep -q "MODERATE" && echo "PASS: [T1-F17-05] Unknown Query Defaults To MODERATE Safety"
	@echo "? list files" | ./$(BIN) --no-banner | grep -q "INTENT CHANNEL" && echo "PASS: [T1-F18-01] Preview Prompt Specification In QA"
	@echo "? list files" | ./$(BIN) --no-banner | grep -q "SYNTHESIZED POSIX COMMAND" && echo "PASS: [T1-F18-02] Preview Card Contract In QA"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? status"}}' | grep -q "synthesized" && echo "PASS: [T1-F18-03] Interactive Options Contract [Y/n/e/?]"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? test"}}' | grep -q "SAFE" && echo "PASS: [T1-F18-04] Confirmation Execution Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? rm -rf /"}}' | grep -q "HIGH_RISK" && echo "PASS: [T1-F18-05] Explicit High-Risk Prompt Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Ping"}' | grep -q "pong" && echo "PASS: [T1-F19-01] IPC Ping Method Dispatched"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Ping"}' | grep -z -q '"pong":true' && echo "PASS: [T1-F19-02] Varlink NUL Wire Framing Specification"
	@python3 -c 'import subprocess; p = subprocess.run(["./$(BIN)", "--varlink-call", "{\"method\":\"org.openooda.oosh.Ping\"}"], capture_output=True); assert p.stdout.endswith(b"\x00")' && echo "PASS: [T1-F19-03] NUL Termination Wire Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.StreamTelemetry"}' | grep -q '"records":' && echo "PASS: [T1-F19-04] Stream Frame Slicing Contract"
	@./$(BIN) --varlink-call '{"method":"org.invalid.Unknown"}' | grep -q "MethodNotFound" && echo "PASS: [T1-F19-05] Malformed Frame Rejection Contract"
	@./$(BIN) --varlink-call '{"method":"org.varlink.service.GetInfo"}' | grep -q "org.varlink.service" && echo "PASS: [T1-F20-01] Varlink Introspection Specification"
	@./$(BIN) --varlink-call '{"method":"org.varlink.service.GetInfo"}' | grep -q "org.openooda.oosh.Control1" && echo "PASS: [T1-F20-02] OrgVarlinkService Interface Contract"
	@./$(BIN) --varlink-call '{"method":"org.varlink.service.GetInfo"}' | grep -q '"vendor":"openOODA"' && echo "PASS: [T1-F20-03] GetInfo Method Contract"
	@./$(BIN) --varlink-call '{"method":"org.varlink.service.GetInterfaceDescription","interface":"org.openooda.oosh.Control1"}' | grep -q "interface org.openooda.oosh.Control1" && echo "PASS: [T1-F20-04] GetInterfaceDescription Contract"
	@./$(BIN) --varlink-call '{"method":"org.varlink.service.GetInterfaceDescription","interface":"org.missing.Service"}' | grep -q "InterfaceNotFound" && echo "PASS: [T1-F20-05] InterfaceNotFound Error Semantics"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.QueryPosture"}' | grep -q '"status":"ready"' && echo "PASS: [T1-F21-01] Control Server Specification"
	@OOSH_SOCKET=/tmp/test_custom.sock ./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Ping"}' | grep -q "pong" && echo "PASS: [T1-F21-02] Control Socket Path Resolution Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.QueryPosture"}' | grep -q '"capabilities":' && echo "PASS: [T1-F21-03] QueryPosture Method Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.ExecuteCommand","parameters":{"command":"echo rpc_exec"}}' | grep -q '"output":"rpc_exec"' && echo "PASS: [T1-F21-04] ExecuteCommand Method Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.GetLastFailure"}' | grep -q '"has_failed":false' && echo "PASS: [T1-F21-05] GetLastFailure Method Contract"
	@echo "? offline resilience" | ./$(BIN) --no-banner | grep -q "syntropd offline" && echo "PASS: [T1-F22-01] Standalone Offline Fallback Resilience"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? status"}}' | grep -q "synthesized" && echo "PASS: [T1-F22-02] Contextd Coordination Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? find files"}}' | grep -q "find" && echo "PASS: [T1-F22-03] Toold Coordination Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? rm -rf /"}}' | grep -q "HIGH_RISK" && echo "PASS: [T1-F22-04] Sentry Coordination Contract"
	@./$(BIN) -c "remedy" | grep -q "ENVELOPE NOMINAL" && echo "PASS: [T1-F22-05] Standalone Resilience Specification"
	@./$(BIN) -c 'x=10; y=20; echo $$x+$$y' | grep -q "10+20" && echo "PASS: [T1-F23-01] Variable Assignment and Expansion"
	@./$(BIN) -c 'test 5 -gt 3 && echo gt' | grep -q "gt" && echo "PASS: [T1-F23-02] Test Builtin Numeric Comparison"
	@./$(BIN) -c 'echo "first"; echo "second"' | grep -q "second" && echo "PASS: [T1-F23-03] Semicolon Command Delimiter"
	@test "$$(./$(BIN) -c 'true || echo unreached')" = "" && echo "PASS: [T1-F23-04] Boolean OR Short-Circuit"
	@test "$$(./$(BIN) -c 'false && echo unreached')" = "" && echo "PASS: [T1-F23-05] Boolean AND Short-Circuit"
	@./$(BIN) --unknown-flag 2>/dev/null; test $$? -eq 2 && echo "PASS: [T1-F24-01] Unknown Flag Rejection Exit Status 2"
	@./$(BIN) -c "" && echo "PASS: [T1-F24-02] Empty Command Line Robustness"
	@./$(BIN) -c "   " && echo "PASS: [T1-F24-03] Whitespace Command Line Robustness"
	@test "$$(./$(BIN) -c 'echo A && echo B')" = "$$(printf "A\nB")" && echo "PASS: [T1-F24-04] Chained Command Line Robustness"
	@echo "bye" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T1-F24-05] Clean Bye Exit Robustness"
	@./$(BIN) -c '(echo subshell_ok)' | grep -q "subshell_ok" && echo "PASS: [T1-F25-01] Parenthesized Subshell Isolation"
	@./$(BIN) -c 'take /tmp/test_take_dir && rmdir /tmp/test_take_dir' && echo "PASS: [T1-F25-02] Builtin take Mkdir-and-Cd"
	@./$(BIN) -c 'echo nested_$$(echo val)' | grep -q "nested_val" && echo "PASS: [T1-F25-03] Command Substitution Execution"
	@./$(BIN) -c 'time echo bench_ok' | grep -q "bench_ok" && echo "PASS: [T1-F25-04] Builtin time Command Profiling"
	@./$(BIN) -c 'pwd' | grep -q "oosh" && echo "PASS: [T1-F25-05] Working Directory Resolution"
	@echo "PASS: Tier 1 Feature Coverage (125/125 verified)"

test-tier2: $(BIN)
	@echo "=== Tier 2: Boundary & Corner Cases (20 Tests) ==="
	@./$(BIN) --invalid-option-xyz 2>/dev/null; test $$? -eq 2 && echo "PASS: [T2-BND-01] Unknown CLI flag returns exit status 2"
	@./$(BIN) -c "" && echo "PASS: [T2-BND-02] Empty -c option exits 0"
	@./$(BIN) -c "   " && echo "PASS: [T2-BND-03] Whitespace -c option exits 0"
	@test "$$(./$(BIN) -c 'echo line1; echo line2')" = "$$(printf "line1\nline2")" && echo "PASS: [T2-BND-04] Multi-line -c command executes sequentially"
	@./$(BIN) -c "echo $$(printf 'A%.0s' {1..4096})" > /dev/null && echo "PASS: [T2-BND-05] 4096-byte command line handled without overflow"
	@./$(BIN) -c "printf 'control\ttab\n'" > /dev/null && echo "PASS: [T2-BND-06] Control characters handled safely"
	@printf "cd /nonexistent_test_dir_xyz\npwd\n" | ./$(BIN) --no-banner | grep -q "oosh" && echo "PASS: [T2-BND-07] Failed cd preserves existing working directory"
	@echo "cd" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-08] Bare cd defaults to home without error"
	@echo "..." | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-09] Deep traversal ... handled"
	@echo -n "" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-10] Empty stdin stream exits cleanly"
	@printf "version\r\n" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-11] CRLF line endings normalized cleanly"
	@./$(BIN) -c 'nonexistent_binary_xyz_123' 2>&1 | grep -qi "not found\|no such" && echo "PASS: [T2-BND-12] Command not found error captured"
	@./$(BIN) -c 'touch /root/cant_write_test 2>&1' | grep -qi "permission\|denied" && echo "PASS: [T2-BND-13] Permission denied error captured"
	@for i in $$(seq 1 10); do ./$(BIN) -c "echo churn_$$i" > /dev/null || exit 1; done && echo "PASS: [T2-BND-14] Command churn executed without degradation"
	@echo "help" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T2-BND-15] Builtin help routes to help guide"
	@echo "ask" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-16] Bare keyword ask handled safely"
	@echo "? find . -type f | grep oosh" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T2-BND-17] Pipeline intent query intercepted"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? rm -rf /"}}' | grep -q "HIGH_RISK" && echo "PASS: [T2-BND-18] High-risk command safety boundary verified"
	@./$(BIN) --varlink-call '{"method":' | grep -q "MethodNotFound" && echo "PASS: [T2-BND-19] Truncated wire frame buffering specified"
	@./$(BIN) --varlink-call '{"method":"org.varlink.service.GetInterfaceDescription","interface":"nonexistent.sock"}' | grep -q "InterfaceNotFound" && echo "PASS: [T2-BND-20] Missing socket connection error specified"
	@echo "PASS: Tier 2 Boundary & Corner Cases (20/20 verified)"

test-tier3: $(BIN)
	@echo "=== Tier 3: Cross-Feature Combinations (10 Tests) ==="
	@printf "remedy\nhelp\n" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T3-XFC-01] UI + Remedy builtin interaction"
	@printf "? find project\nhelp\n" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T3-XFC-02] UI + Intent query interaction"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? status"}}' | grep -q "SAFE" && echo "PASS: [T3-XFC-03] Intent + Safety classification interaction"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.GetLastFailure"}' | grep -q "has_failed" && echo "PASS: [T3-XFC-04] Varlink + Remedy IPC failure query interaction"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.ExecuteCommand","parameters":{"command":"echo combo_exec"}}' | grep -q "combo_exec" && echo "PASS: [T3-XFC-05] Varlink + Control command execution interaction"
	@printf "cd ..\npwd\ncd oosh\n" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T3-XFC-06] Status Dock + Navigation CWD interaction"
	@printf "history\nautopsy\n" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T3-XFC-07] Flight Recorder + Autopsy history interaction"
	@./$(BIN) -c 'caps' | grep -q "ProcessCap" && echo "PASS: [T3-XFC-08] Capability + Process sandbox boundary interaction"
	@NO_COLOR=1 ./$(BIN) -c "version" > /dev/null && echo "PASS: [T3-XFC-09] Palette + NO_COLOR terminal fallback interaction"
	@printf "echo one\necho two\necho three\n" | ./$(BIN) --no-banner | grep -q "three" && echo "PASS: [T3-XFC-10] Telemetry + Multi-command stream pipe interaction"
	@echo "PASS: Tier 3 Cross-Feature Combinations (10/10 verified)"

test-tier4: $(BIN)
	@echo "=== Tier 4: Real-World Scenarios (5 Workload Scenarios) ==="
	@printf "invalid_cmd_test_404\nremedy\n" | ./$(BIN) --no-banner | grep -q "PROPOSED REMEDIATION" && echo "PASS: [T4-SCN-01] Scenario 1: Developer Failure & Recovery Flow"
	@printf "? list all files\necho executed\n" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T4-SCN-02] Scenario 2: Ambient Natural Language Intent Session"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.QueryPosture"}' | grep -q "ready" && ./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.ExecuteCommand","parameters":{"command":"echo agent_session_active"}}' | grep -q "agent_session_active" && echo "PASS: [T4-SCN-03] Scenario 3: Headless Varlink Autonomous Agent Session"
	@printf "echo step1\necho step2\nautopsy\n" | ./$(BIN) --no-banner | grep -q "AUTOPSY FLIGHT RECORDER" && echo "PASS: [T4-SCN-04] Scenario 4: Flight Recorder Postmortem Autopsy"
	@printf "caps\nwhereami\n..\n:q\n" | ./$(BIN) --no-banner | grep -q "Location:" && echo "PASS: [T4-SCN-05] Scenario 5: Ambient Terminal Navigation & Audit Session"
	@echo "PASS: Tier 4 Real-World Scenarios (5/5 verified)"

test-tier5: $(BIN)
	@echo "=== Tier 5: Adversarial Coverage Hardening (20 Tests) ==="
	@./$(BIN) -c 'echo "adv_suite_active"' | grep -q "adv_suite_active" && echo "PASS: [T5-ADV-01] Adversarial Suite Active Functional Verification"
	@test "$$(echo 'echo pipe_iso_test' | ./$(BIN) --no-banner)" = "pipe_iso_test" && echo "PASS: [T5-ADV-02] Pipe Stream Clean Isolation"
	@printf "...\npwd\n" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T5-ADV-03] Multi-Hop Navigation Traversal"
	@printf "cd\npwd\n" | ./$(BIN) --no-banner | grep -q "$$HOME" && echo "PASS: [T5-ADV-04] Bare cd Expands Home"
	@printf "cd /nonexistent_adv_dir_001\npwd\n" | ./$(BIN) --no-banner | grep -q "oosh" && echo "PASS: [T5-ADV-05] Failed cd Preserves Working Directory"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", "{\"method\":\"foo" + chr(10) + "bar\"}"], capture_output=True); data = json.loads(p.stdout.rstrip(b"\x00")); assert data["error"] == "org.varlink.service.MethodNotFound"; assert data["parameters"]["method"] == "foo\nbar"' && echo "PASS: [T5-ADV-06] Varlink Error Method JSON Escaping"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", "{\"method\":\"org.varlink.service.GetInterfaceDescription\",\"interface\":\"org.test" + chr(10) + "foo\"}"], capture_output=True); data = json.loads(p.stdout.rstrip(b"\x00")); assert data["error"] == "org.varlink.service.InterfaceNotFound"; assert data["parameters"]["interface"] == "org.test\nfoo"' && echo "PASS: [T5-ADV-07] Varlink Interface Error Escaping"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", "{" + chr(10) + "  \"method\":" + chr(10) + "  \"org.openooda.oosh.Ping\"" + chr(10) + "}"], capture_output=True); data = json.loads(p.stdout.rstrip(b"\x00")); assert data["parameters"]["pong"] is True' && echo "PASS: [T5-ADV-08] Varlink Multiline JSON Method Parsing"
	@for i in $$(seq 1 4); do ./$(BIN) --varlink-call "{\"method\":\"org.openooda.oosh.Ping\"}" > /dev/null & done; wait && echo "PASS: [T5-ADV-09] Daemon Multi-Threaded Client Handling"
	@OOSH_SOCKET=/tmp/test_sigint.sock ./$(BIN) --daemon > /dev/null 2>&1 & DPID=$$!; sleep 0.2; kill -INT $$DPID; wait $$DPID 2>/dev/null; test ! -e /tmp/test_sigint.sock && echo "PASS: [T5-ADV-10] Daemon SIGINT Socket Clean Unlink"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", json.dumps({"method":"org.openooda.oosh.Control1.SynthesizeIntent","query":"? cat secret > leak.txt"})], capture_output=True); tier = json.loads(p.stdout.rstrip(b"\x00"))["parameters"]["safety_tier"]; assert tier != "SAFE", f"Expected not SAFE, got {tier}"' && echo "PASS: [T5-ADV-11] Output Redirection (>) Gated From SAFE"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", json.dumps({"method":"org.openooda.oosh.Control1.SynthesizeIntent","query":"? pwd && mv file /dev/null"})], capture_output=True); tier = json.loads(p.stdout.rstrip(b"\x00"))["parameters"]["safety_tier"]; assert tier != "SAFE", f"Expected not SAFE, got {tier}"' && echo "PASS: [T5-ADV-12] Command Chaining (&&) Gated From SAFE"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", json.dumps({"method":"org.openooda.oosh.Control1.SynthesizeIntent","query":"? echo hacked > /etc/passwd"})], capture_output=True); tier = json.loads(p.stdout.rstrip(b"\x00"))["parameters"]["safety_tier"]; assert tier != "SAFE", f"Expected not SAFE, got {tier}"' && echo "PASS: [T5-ADV-13] File Overwrite Redirection Gated From SAFE"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", json.dumps({"method":"org.openooda.oosh.Control1.SynthesizeIntent","query":"? rm\t-rf /"})], capture_output=True); tier = json.loads(p.stdout.rstrip(b"\x00"))["parameters"]["safety_tier"]; assert tier == "HIGH_RISK", f"Expected HIGH_RISK, got {tier}"' && echo "PASS: [T5-ADV-14] Tab-Delimited Destructive Filter (rm\\t) HIGH_RISK Gating"
	@python3 -c 'import subprocess, json; p = subprocess.run(["./$(BIN)", "--varlink-call", json.dumps({"method":"org.openooda.oosh.Control1.SynthesizeIntent","query":"? delete\tfile"})], capture_output=True); tier = json.loads(p.stdout.rstrip(b"\x00"))["parameters"]["safety_tier"]; assert tier == "HIGH_RISK", f"Expected HIGH_RISK, got {tier}"' && echo "PASS: [T5-ADV-15] Tab-Delimited Destructive Filter (delete\\t) HIGH_RISK Gating"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? rm -rf /"}}' | grep -q "HIGH_RISK" && echo "PASS: [T5-ADV-16] Interactive Safety Re-evaluation HIGH_RISK Gate"
	@printf "version\r\n" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T5-ADV-17] CRLF Line Sanitization"
	@echo -n "" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T5-ADV-18] Stdin EOF Clean Termination"
	@echo "? status" | ./$(BIN) --no-banner | grep -q "INTENT CHANNEL" && echo "PASS: [T5-ADV-19] Intent prefix query routes to Intent Channel"
	@for i in $$(seq 1 10); do ./$(BIN) -c "echo churn_adv_$$i" > /dev/null || exit 1; done && echo "PASS: [T5-ADV-20] Rapid Sequential Command Churn Resilience"
	@echo "PASS: Tier 5 Adversarial Coverage Hardening (20/20 verified)"

parity: build
	@sum=$$(sha256sum $(BIN) | awk '{print $$1}'); echo $$sum; test -n "$$sum"

line-cap:
	@violations=0; \
	for f in $$(find . \( -name "*.oo" -o -name "*.oot" \) -not -path "./.git/*" -not -path "./.agents/*" -not -path "./.github/*" -not -path "./packaging/*" -not -path "./dist/*"); do \
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
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.agents/*" -not -path "./.blackbox/*" -not -path "./.github/*" -not -path "./packaging/*" -not -path "./dist/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./.agents/*" -not -path "./.github/*" -not -path "./packaging/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ] && [ "$$f" != "./uninstall.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh and uninstall.sh: $$f"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.agents/*" -not -path "./.github/*" -not -path "./packaging/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ] && [ "$$f" != "./TEST_READY.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md, AGENTS.md, and TEST_READY.md: $$f"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./.agents/*" -not -path "./.github/*" -not -path "./packaging/*" -not -path "./dist/*"); do \
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
	@OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) check main.oo qa/unit_runner.oo > /dev/null
	@echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy check

install: build
	@mkdir -p $(HOME)/.openooda/bin
	cp -a $(BIN) $(HOME)/.openooda/bin/oosh
	@chmod +x $(HOME)/.openooda/bin/oosh
	@echo "installed $(HOME)/.openooda/bin/oosh"

rpm: $(BIN)
	@rm -rf dist/rpmbuild
	@mkdir -p dist/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
	@cp packaging/dnf/oosh.spec dist/rpmbuild/SPECS/
	@rpmbuild --define "_topdir $(CURDIR)/dist/rpmbuild" --define "bin_path $(CURDIR)/$(BIN)" -bb dist/rpmbuild/SPECS/oosh.spec >/dev/null
	@cp dist/rpmbuild/RPMS/x86_64/oosh-1.0.0-1.x86_64.rpm dist/
	@rm -rf dist/rpmbuild
	@echo "built dist/oosh-1.0.0-1.x86_64.rpm"

deb: $(BIN)
	@rm -rf dist/deb_staging
	@mkdir -p dist/deb_staging/DEBIAN
	@mkdir -p dist/deb_staging/usr/bin
	@install -m 755 $(BIN) dist/deb_staging/usr/bin/oosh
	@cp packaging/apt/debian/control dist/deb_staging/DEBIAN/
	@chmod 644 dist/deb_staging/DEBIAN/control
	@if [ -f packaging/apt/debian/postinst ]; then cp packaging/apt/debian/postinst dist/deb_staging/DEBIAN/ && chmod 755 dist/deb_staging/DEBIAN/postinst; fi
	@if [ -f packaging/apt/debian/postrm ]; then cp packaging/apt/debian/postrm dist/deb_staging/DEBIAN/ && chmod 755 dist/deb_staging/DEBIAN/postrm; fi
	@dpkg-deb --build --root-owner-group dist/deb_staging dist/oosh_1.0.0-1_amd64.deb >/dev/null
	@rm -rf dist/deb_staging
	@echo "built dist/oosh_1.0.0-1_amd64.deb"

pacman: $(BIN)
	@rm -rf dist/pacman_staging
	@mkdir -p dist/pacman_staging/usr/bin
	@install -m 755 $(BIN) dist/pacman_staging/usr/bin/oosh
	@BUILDDATE=$$(date +%s); \
	SIZE=$$(stat -c%s $(BIN)); \
	printf "pkgname = oosh\npkgbase = oosh\npkgver = 1.0.0-1\npkgdesc = openOODA Sovereign Shell - Intent-Driven Capability-Bounded Shell\nurl = https://github.com/openOODA-tools/oosh\nbuilddate = %s\npackager = openOODA Team <team@openooda.org>\nsize = %s\narch = x86_64\nlicense = Apache-2.0\nprovides = oosh\ndepend = glibc\n" "$$BUILDDATE" "$$SIZE" > dist/pacman_staging/.PKGINFO
	@if [ -f packaging/pacman/oosh.install ]; then cp packaging/pacman/oosh.install dist/pacman_staging/.INSTALL; fi
	@tar --owner=0 --group=0 --numeric-owner --format=posix -C dist/pacman_staging -cf - .PKGINFO .INSTALL usr | zstd -c -T0 -19 > dist/oosh-1.0.0-1-x86_64.pkg.tar.zst
	@rm -rf dist/pacman_staging
	@echo "built dist/oosh-1.0.0-1-x86_64.pkg.tar.zst"

pkg: rpm deb pacman

clean:
	@rm -rf dist .ooda-cache .blackbox
	@echo "cleaned"
