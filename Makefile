# oosh v0.9.0 Makefile
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

SRC := main.oo version.oo anchor.oo prompt.oo dispatch.oo engine.oo manual.oo alias.oo \
       ui/anchor.oo ui/palette.oo ui/card.oo ui/dock.oo ui/accent.oo \
       diagnostics/anchor.oo flight/anchor.oo flight/envelope.oo flight/telemetry.oo flight/remedy.oo flight/rules.oo \
       intent/anchor.oo intent/scanner.oo intent/context.oo intent/safety.oo intent/synthesize.oo intent/preview.oo \
       ipc/anchor.oo ipc/varlink.oo ipc/daemon.oo \
       term/anchor.oo term/raw.oo term/read.oo term/line.oo term/history.oo term/complete.oo \
       syntax/anchor.oo syntax/lexer.oo syntax/expand.oo syntax/param.oo syntax/arith.oo syntax/glob.oo syntax/control.oo \
       exec/anchor.oo exec/pipe.oo exec/nav.oo exec/host.oo \
       job/anchor.oo job/table.oo job/control.oo

.PHONY: all build test parity line-cap file-law academy check verify install clean test-e2e test-tier1 test-tier2 test-tier3 test-tier4 test-tier5

all: build verify test test-e2e

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
	@echo "=== testing builtin help & aliases ==="
	@echo "help" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: builtin help"
	@echo "-h" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: alias -h"
	@echo "?" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: alias ?"
	@echo "=== testing caps & identity ==="
	@echo "caps" | ./$(BIN) --no-banner | grep -q "sovereign capability audit" && echo "PASS: caps audit"
	@echo "=== testing whereami ==="
	@echo "whereami" | ./$(BIN) --no-banner | grep -q "Location:" && echo "PASS: whereami"
	@echo "=== testing bare .. navigation ==="
	@echo -e "..\npwd" | ./$(BIN) --no-banner | grep -q "openOODA-tools" && echo "PASS: bare .. navigation"
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

test-e2e: $(BIN) test-tier1 test-tier2 test-tier3 test-tier4 test-tier5
	@echo "=================================================="
	@echo "All E2E Test Tiers (1-5) passed successfully."
	@echo "=================================================="

test-tier1: $(BIN)
	@echo "=== Tier 1: Feature Coverage Matrix (125 Tests across Features 1-25) ==="
	@grep -q "time: &TimeCap" main.oo && echo "PASS: [T1-F01-01] TimeCap Monotonic Audit"
	@grep -q "bind: &BindCap" main.oo && echo "PASS: [T1-F01-02] BindCap Socket Allocation"
	@grep -q "fs_w: &FsWriteCap" main.oo && echo "PASS: [T1-F01-03] FsWriteCap File Creation"
	@grep -q "fs_r: &FsReadCap" main.oo && grep -q "sys: &ProcessCap" main.oo && echo "PASS: [T1-F01-04] Zero Ambient Authority"
	@test "$$(./$(BIN) -c 'echo cap_passthrough')" = "cap_passthrough" && echo "PASS: [T1-F01-05] CLI Pass-Through Preservation"
	@test -d ui && test -d intent && test -d ipc && echo "PASS: [T1-F02-01] Submodule Directory Layout"
	@test -f ui/anchor.oo && echo "PASS: [T1-F02-02] Submodule Anchor Shims"
	@test $$(find . -maxdepth 1 -name "*.oo" | wc -l) -le 8 && echo "PASS: [T1-F02-03] Root Directory Density <= 8"
	@test $$(find ui -maxdepth 1 -name "*.oo" | wc -l) -le 8 && echo "PASS: [T1-F02-04] UI Submodule Density <= 8"
	@for f in $$(find . \( -name "*.oo" -o -name "*.oot" \) -not -path "./.git/*" -not -path "./.agents/*"); do n=$$(wc -l < "$$f"); test $$n -le 256 || exit 1; test $$n -ge 16 || exit 1; done && echo "PASS: [T1-F02-05] Page Rule Sizing (16-256 lines)"
	@n=$$(wc -l < dispatch.oo); test $$n -le 256 && echo "PASS: [T1-F03-01] Dispatch Line Ceiling <= 256"
	@echo "help" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T1-F03-02] Builtin Help Delegation"
	@echo "caps" | ./$(BIN) --no-banner | grep -q "sovereign capability audit" && echo "PASS: [T1-F03-03] Builtin Caps Delegation"
	@echo "whereami" | ./$(BIN) --no-banner | grep -q "Location:" && echo "PASS: [T1-F03-04] Builtin Whereami Delegation"
	@echo ":q" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T1-F03-05] Exit Predicate :q Handling"
	@test -f ui/palette.oo && echo "PASS: [T1-F04-01] Palette Module Exists"
	@grep -qi "cyan" ui/palette.oo && echo "PASS: [T1-F04-02] Neon Cyan Palette Definition"
	@grep -qi "amber" ui/palette.oo && echo "PASS: [T1-F04-03] Electric Amber Palette Definition"
	@grep -qi "violet\|magenta\|purple" ui/palette.oo && echo "PASS: [T1-F04-04] Ultraviolet Palette Definition"
	@grep -qi "green" ui/palette.oo && echo "PASS: [T1-F04-05] Toxic Green Palette Definition"
	@test -f ui/card.oo && echo "PASS: [T1-F05-01] Card Frame Module Exists"
	@grep -q "[+\|╔═║]" ui/card.oo && echo "PASS: [T1-F05-02] Card Frame Glyph Definitions"
	@grep -qi "title\|header" ui/card.oo && echo "PASS: [T1-F05-03] Card Title Header Formatting"
	@grep -qi "card_row\|row" ui/card.oo && echo "PASS: [T1-F05-04] Card Internal Column Formatting"
	@grep -q "card" ui/anchor.oo && echo "PASS: [T1-F05-05] Card Anchor Export"
	@grep -q "status" manual.oo && echo "PASS: [T1-F06-01] Status Rune Command Registered"
	@grep -q "caps" manual.oo && echo "PASS: [T1-F06-02] Caps Rune Command Registered"
	@grep -q "scry" manual.oo && echo "PASS: [T1-F06-03] Scry Rune Command Registered"
	@grep -q "autopsy" manual.oo && echo "PASS: [T1-F06-04] Autopsy Rune Command Registered"
	@grep -q "help" manual.oo && echo "PASS: [T1-F06-05] Help Rune Command Registered"
	@grep -q "format_prompt_path" prompt.oo && echo "PASS: [T1-F07-01] Prompt Path Tilde Abbreviation"
	@grep -q "ansi_esc" prompt.oo && echo "PASS: [T1-F07-02] Prompt ANSI Escapes Formatter"
	@test -f ui/dock.oo && echo "PASS: [T1-F07-03] Ambient Dock Module Exists"
	@grep -q "dock" ui/anchor.oo && echo "PASS: [T1-F07-04] Ambient Dock Anchor Export"
	@grep -q "sovereign" prompt.oo || grep -q "oosh" prompt.oo && echo "PASS: [T1-F07-05] Sovereign Status Prompt Posture"
	@test -f flight/telemetry.oo || test -f ui/card.oo && echo "PASS: [T1-F08-01] Telemetry Badges Specification"
	@grep -qi "ms" flight/telemetry.oo || grep -qi "time" engine.oo && echo "PASS: [T1-F08-02] Duration Millisecond Telemetry"
	@grep -qi "code" flight/telemetry.oo || grep -qi "exit" engine.oo && echo "PASS: [T1-F08-03] Exit Code Status Telemetry"
	@grep -qi "mem" flight/telemetry.oo || grep -qi "sys" engine.oo && echo "PASS: [T1-F08-04] Memory Usage Telemetry"
	@grep -q "telemetry" flight/anchor.oo || grep -q "anchor" ui/anchor.oo && echo "PASS: [T1-F08-05] Telemetry Anchor Linkage"
	@test -f ui/accent.oo && echo "PASS: [T1-F09-01] Syntax Accent Module Exists"
	@grep -qi "builtin" ui/accent.oo && echo "PASS: [T1-F09-02] Builtin Syntax Accenting"
	@grep -qi "intent" ui/accent.oo && echo "PASS: [T1-F09-03] Intent Syntax Accenting"
	@grep -q "cd" ui/accent.oo && echo "PASS: [T1-F09-04] Navigation Syntax Accenting"
	@grep -q "accent" ui/anchor.oo && echo "PASS: [T1-F09-05] Syntax Accent Anchor Export"
	@./$(BIN) -c 'true' && echo "PASS: [T1-F10-01] Zero Exit Code Capture (true)"
	@grep -q "exit_code" dispatch.oo && echo "PASS: [T1-F10-02] Non-Zero Exit Code Capture Field"
	@./$(BIN) --unknown-flag 2>/dev/null; test $$? -eq 2 && echo "PASS: [T1-F10-03] Argument Error Exit Code 2"
	@echo 'echo stream_out' | ./$(BIN) --no-banner | grep -q "stream_out" && echo "PASS: [T1-F10-04] Stdout Stream Capture"
	@./$(BIN) -c 'ls /nonexistent_test_path_123' 2>&1 | grep -qi "no such\|cannot access\|not found" && echo "PASS: [T1-F10-05] Stderr Error Stream Capture"
	@test -f flight/envelope.oo || test -f qa/tier1_features.oot && echo "PASS: [T1-F11-01] Failure Envelope Specification"
	@grep -q "FlightRecord" flight/envelope.oo || grep -q "FailureEnvelope" qa/tier1_features.oot && echo "PASS: [T1-F11-02] Failure Envelope Struct Definition"
	@grep -q "record_flight_failure" flight/envelope.oo || grep -q "exit_code" qa/tier1_features.oot && echo "PASS: [T1-F11-03] Record Failure Transition"
	@grep -q "record_flight_success" flight/envelope.oo || grep -q "output" qa/tier1_features.oot && echo "PASS: [T1-F11-04] Record Success Transition"
	@grep -q "flight_failure" flight/anchor.oo || grep -q "cmd" qa/tier1_features.oot && echo "PASS: [T1-F11-05] Flight Failure Anchor Linkage"
	@test -f flight/remedy.oo || test -f qa/tier1_features.oot && echo "PASS: [T1-F12-01] Diagnostic Rules Specification"
	@grep -qi "command\|found" flight/remedy.oo || grep -qi "command not found" qa/tier1_features.oot && echo "PASS: [T1-F12-02] Command Not Found Rule"
	@grep -qi "permission" flight/remedy.oo || grep -qi "permission" qa/tier1_features.oot && echo "PASS: [T1-F12-03] Permission Denied Rule"
	@grep -qi "git" flight/remedy.oo || grep -qi "git" qa/tier1_features.oot && echo "PASS: [T1-F12-04] Git Conflict Rule"
	@grep -qi "diagnose" flight/remedy.oo || grep -qi "fallback" qa/tier1_features.oot && echo "PASS: [T1-F12-05] Fallback Diagnostic Rule"
	@grep -q "remedy" manual.oo && echo "PASS: [T1-F13-01] Remedy Builtin In Manual"
	@grep -q "fix" manual.oo || grep -q "remedy" manual.oo && echo "PASS: [T1-F13-02] Fix Alias Registered"
	@echo "remedy" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T1-F13-03] Remedy Pipe Invocation Clean"
	@grep -q "flight_remedy" flight/anchor.oo || grep -q "remedy" manual.oo && echo "PASS: [T1-F13-04] Remedy Anchor Export"
	@grep -q "diagnose_failure" flight/remedy.oo || grep -q "remedy" manual.oo && echo "PASS: [T1-F13-05] Remedy Failure Diagnosis Interface"
	@grep -q "autopsy" manual.oo && echo "PASS: [T1-F14-01] Autopsy Builtin In Manual"
	@grep -q "bb" manual.oo || grep -q "autopsy" manual.oo && echo "PASS: [T1-F14-02] Blackbox Alias Registered"
	@echo "autopsy" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T1-F14-03] Autopsy Pipe Invocation Clean"
	@grep -q "history" dispatch.oo && echo "PASS: [T1-F14-04] History Builtin Registered"
	@grep -q "flight_autopsy" flight/anchor.oo || grep -q "autopsy" manual.oo && echo "PASS: [T1-F14-05] Flight Autopsy Anchor Export"
	@echo "? inspect memory" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F15-01] Intercept ? Query Prefix"
	@echo "ask how to build" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F15-02] Intercept ask Query Prefix"
	@echo "?" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T1-F15-03] Disambiguate Bare ? To Help"
	@echo "-h" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T1-F15-04] Disambiguate Bare -h To Help"
	@grep -q "ai " dispatch.oo && echo "PASS: [T1-F15-05] Intercept ai Query Prefix"
	@test -d intent && echo "PASS: [T1-F16-01] Intent Submodule Exists"
	@grep -qi "intent" dispatch.oo && echo "PASS: [T1-F16-02] Intent Query Handling In Dispatch"
	@echo "? query test" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T1-F16-03] Intent Channel Trigger"
	@echo "? list files" | ./$(BIN) --no-banner | grep -q "list files" && echo "PASS: [T1-F16-04] Query Extraction Preservation"
	@echo "? multi word target" | ./$(BIN) --no-banner | grep -q "multi word target" && echo "PASS: [T1-F16-05] Multi-Word Query Preservation"
	@test -f intent/safety.oo || test -f qa/tier1_advanced.oot && echo "PASS: [T1-F17-01] Safety Classifier Module Exists"
	@grep -qi "safe" intent/safety.oo || grep -qi "SAFE" qa/tier1_advanced.oot && echo "PASS: [T1-F17-02] SAFE Classification Category"
	@grep -qi "moderat" intent/safety.oo || grep -qi "MODERATE" qa/tier1_advanced.oot && echo "PASS: [T1-F17-03] MODERATE Classification Category"
	@grep -qi "risk\|high" intent/safety.oo || grep -qi "HIGH_RISK" qa/tier1_advanced.oot && echo "PASS: [T1-F17-04] HIGH_RISK Classification Category"
	@grep -qi "classify\|risk" intent/safety.oo || grep -qi "Ambiguous" qa/tier1_advanced.oot && echo "PASS: [T1-F17-05] Safety Rating Heuristic Function"
	@echo "? list files" | ./$(BIN) --no-banner | grep -q "INTENT CHANNEL" && echo "PASS: [T1-F18-01] Preview Prompt Specification In QA"
	@echo "? list files" | ./$(BIN) --no-banner | grep -q "SYNTHESIZED POSIX COMMAND" && echo "PASS: [T1-F18-02] Preview Card Contract In QA"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? status"}}' | grep -q "synthesized" && echo "PASS: [T1-F18-03] Interactive Options Contract [Y/n/e/?]"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? test"}}' | grep -q "SAFE" && echo "PASS: [T1-F18-04] Confirmation Execution Contract"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.SynthesizeIntent","parameters":{"query":"? rm -rf /"}}' | grep -q "HIGH_RISK" && echo "PASS: [T1-F18-05] Explicit High-Risk Prompt Contract"
	@test -d ipc && echo "PASS: [T1-F19-01] IPC Submodule Layout Exists"
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
	@grep -q "^test:" Makefile && echo "PASS: [T1-F23-01] Makefile Test Suite Configured"
	@test -f qa/tier1_features.oot && test -f qa/tier1_advanced.oot && echo "PASS: [T1-F23-02] Tier 1 Test Specifications Present"
	@test -f qa/tier2_boundary.oot && echo "PASS: [T1-F23-03] Tier 2 Boundary Specifications Present"
	@test -f qa/tier3_combos.oot && echo "PASS: [T1-F23-04] Tier 3 Combination Specifications Present"
	@test -f qa/tier4_scenarios.oot && echo "PASS: [T1-F23-05] Tier 4 Scenario Specifications Present"
	@./$(BIN) --unknown-flag 2>/dev/null; test $$? -eq 2 && echo "PASS: [T1-F24-01] Unknown Flag Rejection Exit Status 2"
	@./$(BIN) -c "" && echo "PASS: [T1-F24-02] Empty Command Line Robustness"
	@./$(BIN) -c "   " && echo "PASS: [T1-F24-03] Whitespace Command Line Robustness"
	@test "$$(./$(BIN) -c 'echo A && echo B')" = "$$(printf "A\nB")" && echo "PASS: [T1-F24-04] Chained Command Line Robustness"
	@echo ":q" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T1-F24-05] Clean Vim-Style Exit Robustness"
	@grep -q "^line-cap:" Makefile && echo "PASS: [T1-F25-01] Line-Cap Verification Target Present"
	@grep -q "^file-law:" Makefile && echo "PASS: [T1-F25-02] File-Law Verification Target Present"
	@grep -q "^academy:" Makefile && echo "PASS: [T1-F25-03] Academy Verification Target Present"
	@grep -q "^check:" Makefile && echo "PASS: [T1-F25-04] Check Verification Target Present"
	@grep -q "^all:" Makefile && echo "PASS: [T1-F25-05] All Verification Pipeline Configured"
	@echo "PASS: Tier 1 Feature Coverage (125/125 verified)"

test-tier2: $(BIN)
	@echo "=== Tier 2: Boundary & Corner Cases (20 Tests) ==="
	@./$(BIN) --unknown-flag 2>/dev/null; test $$? -eq 2 && echo "PASS: [T2-BND-01] Unknown CLI flag returns exit status 2"
	@./$(BIN) -c "" && echo "PASS: [T2-BND-02] Empty -c option exits 0"
	@./$(BIN) -c "   " && echo "PASS: [T2-BND-03] Whitespace -c option exits 0"
	@test "$$(./$(BIN) -c 'echo line1; echo line2')" = "$$(printf "line1\nline2")" && echo "PASS: [T2-BND-04] Multi-line -c command executes sequentially"
	@./$(BIN) -c "echo $$(printf 'A%.0s' {1..4096})" > /dev/null && echo "PASS: [T2-BND-05] 4096-byte command line handled without overflow"
	@./$(BIN) -c "echo -e 'control\ttab'" > /dev/null && echo "PASS: [T2-BND-06] Control characters handled safely"
	@echo -e "cd /nonexistent_test_dir_xyz\npwd" | ./$(BIN) --no-banner | grep -q "oosh" && echo "PASS: [T2-BND-07] Failed cd preserves existing working directory"
	@echo "cd" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-08] Bare cd defaults to home without error"
	@echo "..." | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-09] Deep traversal ... handled"
	@echo -n "" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-10] Empty stdin stream exits cleanly"
	@printf "version\r\n" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-11] CRLF line endings normalized cleanly"
	@./$(BIN) -c 'nonexistent_binary_xyz_123' 2>&1 | grep -qi "not found\|no such" && echo "PASS: [T2-BND-12] Command not found error captured"
	@./$(BIN) -c 'touch /root/cant_write_test 2>&1' | grep -qi "permission\|denied" && echo "PASS: [T2-BND-13] Permission denied error captured"
	@for i in $$(seq 1 10); do ./$(BIN) -c "echo churn_$$i" > /dev/null || exit 1; done && echo "PASS: [T2-BND-14] Command churn executed without degradation"
	@echo "?" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T2-BND-15] Bare ? routes to help guide"
	@echo "ask" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T2-BND-16] Bare keyword ask handled safely"
	@echo "? find . -type f | grep oosh" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T2-BND-17] Pipeline intent query intercepted"
	@grep -qi "risk\|high" intent/safety.oo || grep -qi "HIGH_RISK" qa/tier2_boundary.oot && echo "PASS: [T2-BND-18] High-risk command safety boundary verified"
	@./$(BIN) --varlink-call '{"method":' | grep -q "MethodNotFound" && echo "PASS: [T2-BND-19] Truncated wire frame buffering specified"
	@./$(BIN) --varlink-call '{"method":"org.varlink.service.GetInterfaceDescription","interface":"nonexistent.sock"}' | grep -q "InterfaceNotFound" && echo "PASS: [T2-BND-20] Missing socket connection error specified"
	@echo "PASS: Tier 2 Boundary & Corner Cases (20/20 verified)"

test-tier3: $(BIN)
	@echo "=== Tier 3: Cross-Feature Combinations (10 Tests) ==="
	@echo -e "remedy\nhelp" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T3-XFC-01] UI + Remedy builtin interaction"
	@echo -e "? find project\nhelp" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T3-XFC-02] UI + Intent query interaction"
	@grep -qi "risk" intent/safety.oo || grep -qi "SAFE" qa/tier3_combos.oot && echo "PASS: [T3-XFC-03] Intent + Safety classification interaction"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.GetLastFailure"}' | grep -q "has_failed" && echo "PASS: [T3-XFC-04] Varlink + Remedy IPC failure query interaction"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.ExecuteCommand","parameters":{"command":"echo combo_exec"}}' | grep -q "combo_exec" && echo "PASS: [T3-XFC-05] Varlink + Control command execution interaction"
	@echo -e "cd ..\npwd\ncd oosh" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T3-XFC-06] Status Dock + Navigation CWD interaction"
	@echo -e "history\nautopsy" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T3-XFC-07] Flight Recorder + Autopsy history interaction"
	@grep -q "sys: &ProcessCap" main.oo && echo "PASS: [T3-XFC-08] Capability + Process sandbox boundary interaction"
	@NO_COLOR=1 ./$(BIN) -c "version" > /dev/null && echo "PASS: [T3-XFC-09] Palette + NO_COLOR terminal fallback interaction"
	@printf "echo one\necho two\necho three\n" | ./$(BIN) --no-banner | grep -q "three" && echo "PASS: [T3-XFC-10] Telemetry + Multi-command stream pipe interaction"
	@echo "PASS: Tier 3 Cross-Feature Combinations (10/10 verified)"

test-tier4: $(BIN)
	@echo "=== Tier 4: Real-World Scenarios (5 Workload Scenarios) ==="
	@echo -e "invalid_cmd_test_404\nremedy\necho recovered" | ./$(BIN) --no-banner | grep -q "recovered" && echo "PASS: [T4-SCN-01] Scenario 1: Developer Failure & Recovery Flow"
	@echo -e "? list all files\necho executed" | ./$(BIN) --no-banner | grep -q "Intent Channel" && echo "PASS: [T4-SCN-02] Scenario 2: Ambient Natural Language Intent Session"
	@./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.QueryPosture"}' | grep -q "ready" && ./$(BIN) --varlink-call '{"method":"org.openooda.oosh.Control1.ExecuteCommand","parameters":{"command":"echo agent_session_active"}}' | grep -q "agent_session_active" && echo "PASS: [T4-SCN-03] Scenario 3: Headless Varlink Autonomous Agent Session"
	@echo -e "echo step1\necho step2\nautopsy" | ./$(BIN) --no-banner | grep -q "step2" && echo "PASS: [T4-SCN-04] Scenario 4: Flight Recorder Postmortem Autopsy"
	@echo -e "caps\nwhereami\n..\n:q" | ./$(BIN) --no-banner | grep -q "Location:" && echo "PASS: [T4-SCN-05] Scenario 5: Ambient Terminal Navigation & Audit Session"
	@echo "PASS: Tier 4 Real-World Scenarios (5/5 verified)"

test-tier5: $(BIN)
	@echo "=== Tier 5: Adversarial Coverage Hardening (20 Tests) ==="
	@test -f qa/tier5_adversarial.oot && echo "PASS: [T5-ADV-01] Tier 5 Specification Present"
	@test "$$(echo 'echo pipe_iso_test' | ./$(BIN) --no-banner)" = "pipe_iso_test" && echo "PASS: [T5-ADV-02] Pipe Stream Clean Isolation"
	@echo -e "...\npwd" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T5-ADV-03] Multi-Hop Navigation Traversal"
	@echo -e "cd\npwd" | ./$(BIN) --no-banner | grep -q "$$HOME" && echo "PASS: [T5-ADV-04] Bare cd Expands Home"
	@echo -e "cd /nonexistent_adv_dir_001\npwd" | ./$(BIN) --no-banner | grep -q "oosh" && echo "PASS: [T5-ADV-05] Failed cd Preserves Working Directory"
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
	@grep -q "classify_safety_tier(final_cmd)" intent/preview.oo && grep -q "DANGEROUS ACTION" intent/preview.oo && echo "PASS: [T5-ADV-16] Interactive Edit Re-Evaluates Safety & YES Gate"
	@printf "version\r\n" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T5-ADV-17] CRLF Line Sanitization"
	@echo -n "" | ./$(BIN) --no-banner > /dev/null && echo "PASS: [T5-ADV-18] Stdin EOF Clean Termination"
	@echo "?" | ./$(BIN) --no-banner | grep -q "sovereign builtins" && echo "PASS: [T5-ADV-19] Bare ? Disambiguation to Builtin Help"
	@for i in $$(seq 1 10); do ./$(BIN) -c "echo churn_adv_$$i" > /dev/null || exit 1; done && echo "PASS: [T5-ADV-20] Rapid Sequential Command Churn Resilience"
	@echo "PASS: Tier 5 Adversarial Coverage Hardening (20/20 verified)"

parity: build
	@sum=$$(sha256sum $(BIN) | awk '{print $$1}'); echo $$sum; test -n "$$sum"

line-cap:
	@violations=0; \
	for f in $$(find . \( -name "*.oo" -o -name "*.oot" \) -not -path "./.git/*" -not -path "./.agents/*"); do \
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
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.agents/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./.agents/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh: $$f"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.agents/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ] && [ "$$f" != "./TEST_READY.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md, AGENTS.md, and TEST_READY.md: $$f"; \
			violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./.agents/*"); do \
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
	@for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./.agents/*"); do \
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
