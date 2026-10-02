# TEST_READY: oosh Test Suite & House Laws Certification

## Executive Summary
- **Target**: `oosh` (openOODA Sovereign Shell) Phase 3 "Sovereign Superpowers" (v0.9.0)
- **Certification Date**: 2026-10-02
- **Certification Status**: **100% GREEN (CERTIFIED)**
- **Total Test Counts**:
  - Smoke Tests: **35 / 35 PASS**
  - E2E Tests: **180 / 180 PASS** across Tiers 1–5
  - Build & Verification Pipeline (`make all`): **PASS**
  - House Laws Compliance: **100% (Zero Violations)**
    - Page Rule (16–256 lines): 51/51 files compliant (min: 17, max: 255)
    - Directory Density (<= 8 `.oo` files/dir, root exactly 8): 10/10 directories compliant
    - Academy Docstrings (4-element headers in lines 1–7): 45/45 `.oo` files compliant
    - File Law: Zero forbidden extensions/files
    - Type Checking (`oodac check`): 45/45 `.oo` files verified clean

---

## Test Runner Commands & Semantics

### Primary Verification Targets

| Command | Purpose | Expected Result | Fail-Closed Semantics |
|---|---|---|---|
| `make test-e2e` | Full 180 E2E test suite across Tiers 1–5 | `All E2E Test Tiers (1-5) passed successfully.` (exit 0) | Halts on first tier failure; non-zero exit |
| `make test` | 35 CLI, builtin, stream, and syntax smoke tests | All 35 tests print `PASS:` (exit 0) | Fails on any assertion mismatch; non-zero exit |
| `make all` | Complete release pipeline: build + verify + test + test-e2e | Clean binary build, verified House Laws, 215 green tests | Fails on any stage |
| `make verify` | Enforces all 4 openOODA House Laws | `line-cap`, `file-law`, `academy`, `check` pass | Exits non-zero on any violation |
| `make line-cap` | Page Rule verification across all `.oo` and `.oot` files | `PASS: Page Rule sizing (16-256 lines) holds` | Exits 1 with violation listing |
| `make file-law` | File law enforcement (forbidden scripts, markup, data) | `PASS: file law holds` | Exits 1 with file list |
| `make academy` | 4-element Academy header verification | `PASS: academy headers hold` | Exits 1 if title, logline, setup, or beats missing |
| `make check` | `oodac check` type-checker invocation on all `.oo` files | `PASS: oodac check holds on all .oo files` | Exits non-zero on syntax or type error |
| `make parity` | Cryptographic SHA-256 seal verification on binary | Prints SHA-256 hash (exit 0) | Exits non-zero if binary missing or empty |

### Pass/Fail Semantics
- **Zero Exit (0)**: Certified clean. Every assertion, file size check, docstring constraint, and behavioral test passed without warning or error.
- **Non-Zero Exit (!= 0)**: Strict fail-closed failure. The pipeline aborts immediately on any single failure, printing verbatim diagnostic details.

---

## Complete 180 E2E Test Breakdown

### Tier 1: Feature Coverage Matrix (125 Tests)
25 distinct architecture features verified with 5 tests per feature:

- **[T1-F01] Capability Plumbing (5/5)**
  - `[T1-F01-01]` TimeCap Monotonic Audit (`now_ms(time)` monotonicity in execution loop)
  - `[T1-F01-02]` BindCap Socket Allocation (`bind: &BindCap` passed for AF_UNIX control socket)
  - `[T1-F01-03]` FsWriteCap File Creation (`fs_w: &FsWriteCap` capability segregation)
  - `[T1-F01-04]` Zero Ambient Authority (`fs_r`, `sys` capability encapsulation)
  - `[T1-F01-05]` CLI Pass-Through Preservation (`-c`, `--help`, `--version` option pass-through)

- **[T1-F02] Submodule Scaffold & House Laws (5/5)**
  - `[T1-F02-01]` Submodule Directory Layout (`ui/`, `intent/`, `ipc/` structural presence)
  - `[T1-F02-02]` Submodule Anchor Shims (`anchor.oo` public symbol facade)
  - `[T1-F02-03]` Root Directory Density (`find . -maxdepth 1 -name "*.oo"` <= 8 files)
  - `[T1-F02-04]` UI Submodule Density (`find ui -maxdepth 1 -name "*.oo"` <= 8 files)
  - `[T1-F02-05]` Page Rule Sizing (All `.oo` and `.oot` strictly 16–256 lines)

- **[T1-F03] Dispatch Refactoring (5/5)**
  - `[T1-F03-01]` Dispatch Line Ceiling (`dispatch.oo` <= 256 lines)
  - `[T1-F03-02]` Builtin Help Delegation (`help` builtin delegated cleanly)
  - `[T1-F03-03]` Builtin Caps Delegation (`caps` capability audit delegated cleanly)
  - `[T1-F03-04]` Builtin Whereami Delegation (`whereami` node location delegated cleanly)
  - `[T1-F03-05]` Exit Predicate `:q` Handling (Vim-style `:q` terminates session)

- **[T1-F04] TrueColor/ANSI Palette (5/5)**
  - `[T1-F04-01]` Palette Module Exists (`ui/palette.oo` present)
  - `[T1-F04-02]` Neon Cyan Palette Definition (Cyan ANSI sequence for builtins)
  - `[T1-F04-03]` Electric Amber Palette Definition (Amber sequence for warnings and external binaries)
  - `[T1-F04-04]` Ultraviolet Palette Definition (Ultraviolet sequence for intent and AI queries)
  - `[T1-F04-05]` Toxic Green Palette Definition (Toxic green for navigation and successful glyphs)

- **[T1-F05] Double-Lined Cards (5/5)**
  - `[T1-F05-01]` Card Frame Module Exists (`ui/card.oo` present)
  - `[T1-F05-02]` Card Frame Glyph Definitions (Double box glyphs: `╔`, `═`, `║`, `╚`)
  - `[T1-F05-03]` Card Title Header Formatting (Component header framing)
  - `[T1-F05-04]` Card Internal Column Formatting (Internal line column padding)
  - `[T1-F05-05]` Card Anchor Export (Public export via `ui/anchor.oo`)

- **[T1-F06] Pixel Art Runes (5/5)**
  - `[T1-F06-01]` Status Rune Command Registered (Odal rune for status card)
  - `[T1-F06-02]` Caps Rune Command Registered (Tiwaz rune for capability card)
  - `[T1-F06-03]` Scry Rune Command Registered (Peorth rune for scry card)
  - `[T1-F06-04]` Autopsy Rune Command Registered (Hagalaz rune for autopsy card)
  - `[T1-F06-05]` Help Rune Command Registered (Raidho rune for help card)

- **[T1-F07] Ambient Status Dock (5/5)**
  - `[T1-F07-01]` Prompt Path Tilde Abbreviation (`format_prompt_path` abbreviates `$HOME` to `~`)
  - `[T1-F07-02]` Prompt ANSI Escapes Formatter (`ansi_esc` ANSI wrapper)
  - `[T1-F07-03]` Ambient Dock Module Exists (`ui/dock.oo` present)
  - `[T1-F07-04]` Ambient Dock Anchor Export (Public export via `ui/anchor.oo`)
  - `[T1-F07-05]` Sovereign Status Prompt Posture (Dock displays host posture)

- **[T1-F08] Execution Telemetry Badges (5/5)**
  - `[T1-F08-01]` Telemetry Badges Specification (`flight/telemetry.oo` present)
  - `[T1-F08-02]` Duration Millisecond Telemetry (Format `⏱ <ms>ms`)
  - `[T1-F08-03]` Exit Code Status Telemetry (`✔` on 0, `✘ <code>` on non-zero)
  - `[T1-F08-04]` Memory Usage Telemetry (RSS memory in KB/MB from `/proc/self/statm`)
  - `[T1-F08-05]` Telemetry Anchor Linkage (Public export via `flight/anchor.oo`)

- **[T1-F09] Syntax Accenting (5/5)**
  - `[T1-F09-01]` Syntax Accent Module Exists (`ui/accent.oo` present)
  - `[T1-F09-02]` Builtin Syntax Accenting (Accenting for sovereign builtins)
  - `[T1-F09-03]` Intent Syntax Accenting (Accenting for `?`, `ai`, `ask`)
  - `[T1-F09-04]` Navigation Syntax Accenting (Accenting for `cd`, `..`, `take`)
  - `[T1-F09-05]` Syntax Accent Anchor Export (Public export via `ui/anchor.oo`)

- **[T1-F10] Exit Code & Stream Capture (5/5)**
  - `[T1-F10-01]` Zero Exit Code Capture (`true` returns exit status 0)
  - `[T1-F10-02]` Non-Zero Exit Code Capture Field (`res.exit_code` capture field)
  - `[T1-F10-03]` Argument Error Exit Code 2 (Unknown flag returns status 2)
  - `[T1-F10-04]` Stdout Stream Capture (Standard output stream capture in envelope)
  - `[T1-F10-05]` Stderr Error Stream Capture (Standard error stream capture in envelope)

- **[T1-F11] Failure Envelope (5/5)**
  - `[T1-F11-01]` Failure Envelope Specification (`flight/envelope.oo` present)
  - `[T1-F11-02]` Failure Envelope Struct Definition (`FlightRecord` / `FlightEntry`)
  - `[T1-F11-03]` Record Failure Transition (`record_flight_failure` handler)
  - `[T1-F11-04]` Record Success Transition (`record_flight_success` handler)
  - `[T1-F11-05]` Flight Failure Anchor Linkage (Export via `flight/anchor.oo`)

- **[T1-F12] Diagnostic Pattern Rules (5/5)**
  - `[T1-F12-01]` Diagnostic Rules Specification (`flight/remedy.oo` present)
  - `[T1-F12-02]` Command Not Found Rule (Exit status 127 pattern rule)
  - `[T1-F12-03]` Permission Denied Rule (Exit status 126 pattern rule)
  - `[T1-F12-04]` Git Conflict Rule (Git merge conflict pattern rule)
  - `[T1-F12-05]` Fallback Diagnostic Rule (Generic actionable failure guidance)

- **[T1-F13] Remedy / Fix Builtin (5/5)**
  - `[T1-F13-01]` Remedy Builtin In Manual (`remedy` registered in manual)
  - `[T1-F13-02]` Fix Alias Registered (`fix` registered as alias for remedy)
  - `[T1-F13-03]` Remedy Pipe Invocation Clean (Pipe invocation executes cleanly)
  - `[T1-F13-04]` Remedy Anchor Export (Export via `flight/anchor.oo`)
  - `[T1-F13-05]` Remedy Failure Diagnosis Interface (`diagnose_failure` API)

- **[T1-F14] Flight Recorder Ring Buffer & Autopsy (5/5)**
  - `[T1-F14-01]` Autopsy Builtin In Manual (`autopsy` registered in manual)
  - `[T1-F14-02]` Blackbox Alias Registered (`bb` alias registered)
  - `[T1-F14-03]` Autopsy Pipe Invocation Clean (Pipe invocation executes cleanly)
  - `[T1-F14-04]` History Builtin Registered (`history` registered in dispatch)
  - `[T1-F14-05]` Flight Autopsy Anchor Export (Export via `flight/anchor.oo`)

- **[T1-F15] Query Prefix Interception (5/5)**
  - `[T1-F15-01]` Intercept `?` Query Prefix (`? <query>` routed to intent)
  - `[T1-F15-02]` Intercept `ask` Query Prefix (`ask <query>` routed to intent)
  - `[T1-F15-03]` Disambiguate Bare `?` To Help (Bare `?` opens builtin help)
  - `[T1-F15-04]` Disambiguate Bare `-h` To Help (Bare `-h` opens builtin help)
  - `[T1-F15-05]` Intercept `ai` Query Prefix (`ai <query>` routed to intent)

- **[T1-F16] POSIX Command Synthesis (5/5)**
  - `[T1-F16-01]` Intent Submodule Exists (`intent/` module layout)
  - `[T1-F16-02]` Intent Query Handling In Dispatch (Dispatch routing logic)
  - `[T1-F16-03]` Intent Channel Trigger (Natural language query activation)
  - `[T1-F16-04]` Query Extraction Preservation (Preserves query arguments)
  - `[T1-F16-05]` Multi-Word Query Preservation (Multi-token preservation)

- **[T1-F17] Safety Classification (5/5)**
  - `[T1-F17-01]` Safety Classifier Module Exists (`intent/safety.oo` present)
  - `[T1-F17-02]` SAFE Classification Category (Read-only commands)
  - `[T1-F17-03]` MODERATE Classification Category (Mutating safe commands)
  - `[T1-F17-04]` HIGH_RISK Classification Category (Destructive commands)
  - `[T1-F17-05]` Safety Rating Heuristic Function (`classify_safety_tier`)

- **[T1-F18] Preview & Execution Prompt (5/5)**
  - `[T1-F18-01]` Preview Prompt Specification In QA (`INTENT CHANNEL` frame)
  - `[T1-F18-02]` Preview Card Contract In QA (`SYNTHESIZED POSIX COMMAND`)
  - `[T1-F18-03]` Interactive Options Contract `[Y/n/e/?]`
  - `[T1-F18-04]` Confirmation Execution Contract (`SAFE` execution gate)
  - `[T1-F18-05]` Explicit High-Risk Prompt Contract (`HIGH_RISK` execution gate)

- **[T1-F19] Varlink NUL Wire Framing (5/5)**
  - `[T1-F19-01]` IPC Submodule Layout Exists (`ipc/` module layout)
  - `[T1-F19-02]` Varlink NUL Wire Framing Specification (`\0` wire framing)
  - `[T1-F19-03]` NUL Termination Wire Contract (Responses end with `\0`)
  - `[T1-F19-04]` Stream Frame Slicing Contract (Multi-frame demuxing)
  - `[T1-F19-05]` Malformed Frame Rejection Contract (`MethodNotFound` / error)

- **[T1-F20] Varlink Introspection (5/5)**
  - `[T1-F20-01]` Varlink Introspection Specification (`org.varlink.service`)
  - `[T1-F20-02]` OrgVarlinkService Interface Contract (`org.openooda.oosh.Control1`)
  - `[T1-F20-03]` GetInfo Method Contract (Vendor, product, version, URL)
  - `[T1-F20-04]` GetInterfaceDescription Contract (IDL specification output)
  - `[T1-F20-05]` InterfaceNotFound Error Semantics (Missing interface error)

- **[T1-F21] oosh Control Server (5/5)**
  - `[T1-F21-01]` Control Server Specification (`ready` status)
  - `[T1-F21-02]` Control Socket Path Resolution Contract (Fallback hierarchy)
  - `[T1-F21-03]` QueryPosture Method Contract (Capabilities and posture reporting)
  - `[T1-F21-04]` ExecuteCommand Method Contract (Command execution over IPC)
  - `[T1-F21-05]` GetLastFailure Method Contract (Failure envelope over IPC)

- **[T1-F22] syntropd Integration (5/5)**
  - `[T1-F22-01]` Standalone Offline Fallback Resilience (Handles offline daemon)
  - `[T1-F22-02]` Contextd Coordination Contract (`io.syntrop.Context1`)
  - `[T1-F22-03]` Toold Coordination Contract (`io.syntrop.Tool1`)
  - `[T1-F22-04]` Sentry Coordination Contract (`io.syntrop.Sentry1`)
  - `[T1-F22-05]` Standalone Resilience Specification (Nominal fallback envelope)

- **[T1-F23] E2E Test Suite Infrastructure (5/5)**
  - `[T1-F23-01]` Makefile Test Suite Configured (`test` target present)
  - `[T1-F23-02]` Tier 1 Test Specifications Present (`tier1_features.oot`, `tier1_advanced.oot`)
  - `[T1-F23-03]` Tier 2 Boundary Specifications Present (`tier2_boundary.oot`)
  - `[T1-F23-04]` Tier 3 Combination Specifications Present (`tier3_combos.oot`)
  - `[T1-F23-05]` Tier 4 Scenario Specifications Present (`tier4_scenarios.oot`)

- **[T1-F24] Adversarial Robustness & Churn Resilience (5/5)**
  - `[T1-F24-01]` Unknown Flag Rejection Exit Status 2 (`--unknown-flag`)
  - `[T1-F24-02]` Empty Command Line Robustness (`-c ""`)
  - `[T1-F24-03]` Whitespace Command Line Robustness (`-c "   "`)
  - `[T1-F24-04]` Chained Command Line Robustness (`echo A && echo B`)
  - `[T1-F24-05]` Clean Vim-Style Exit Robustness (`:q`)

- **[T1-F25] Verification Gate Targets (5/5)**
  - `[T1-F25-01]` Line-Cap Verification Target Present (`line-cap:`)
  - `[T1-F25-02]` File-Law Verification Target Present (`file-law:`)
  - `[T1-F25-03]` Academy Verification Target Present (`academy:`)
  - `[T1-F25-04]` Check Verification Target Present (`check:`)
  - `[T1-F25-05]` All Verification Pipeline Configured (`all:`)

---

### Tier 2: Boundary & Corner Cases (20 Tests)
- `[T2-BND-01]` Unknown CLI flag returns exit status 2
- `[T2-BND-02]` Empty `-c` option exits 0
- `[T2-BND-03]` Whitespace `-c` option exits 0
- `[T2-BND-04]` Multi-line `-c` command executes sequentially
- `[T2-BND-05]` 4096-byte command line handled without overflow
- `[T2-BND-06]` Control characters handled safely
- `[T2-BND-07]` Failed `cd` preserves existing working directory
- `[T2-BND-08]` Bare `cd` defaults to home without error
- `[T2-BND-09]` Deep traversal `...` handled
- `[T2-BND-10]` Empty stdin stream exits cleanly
- `[T2-BND-11]` CRLF line endings normalized cleanly
- `[T2-BND-12]` Command not found error captured (exit 127)
- `[T2-BND-13]` Permission denied error captured (exit 126)
- `[T2-BND-14]` Command churn executed without degradation (10x sequential)
- `[T2-BND-15]` Bare `?` routes to help guide
- `[T2-BND-16]` Bare keyword `ask` handled safely
- `[T2-BND-17]` Pipeline intent query intercepted
- `[T2-BND-18]` High-risk command safety boundary verified
- `[T2-BND-19]` Truncated wire frame buffering specified
- `[T2-BND-20]` Missing socket connection error specified

---

### Tier 3: Cross-Feature Combinations (10 Tests)
- `[T3-XFC-01]` UI + Remedy builtin interaction
- `[T3-XFC-02]` UI + Intent query interaction
- `[T3-XFC-03]` Intent + Safety classification interaction
- `[T3-XFC-04]` Varlink + Remedy IPC failure query interaction
- `[T3-XFC-05]` Varlink + Control command execution interaction
- `[T3-XFC-06]` Status Dock + Navigation CWD interaction
- `[T3-XFC-07]` Flight Recorder + Autopsy history interaction
- `[T3-XFC-08]` Capability + Process sandbox boundary interaction
- `[T3-XFC-09]` Palette + `NO_COLOR` terminal fallback interaction
- `[T3-XFC-10]` Telemetry + Multi-command stream pipe interaction

---

### Tier 4: Real-World Scenarios (5 Workload Scenarios)
- `[T4-SCN-01]` Scenario 1: Developer Failure & Recovery Flow (failing cmd -> diagnosis -> fix suggestion -> green recovery)
- `[T4-SCN-02]` Scenario 2: Ambient Natural Language Intent Session (dock display -> `? list files` -> synthesized POSIX command -> prompt execution)
- `[T4-SCN-03]` Scenario 3: Headless Varlink Autonomous Agent Session (daemon binding -> `QueryPosture` -> `ExecuteCommand` -> NUL stream output)
- `[T4-SCN-04]` Scenario 4: Flight Recorder Postmortem Autopsy (multi-command execution -> intermediate failure -> columnar autopsy postmortem timeline)
- `[T4-SCN-05]` Scenario 5: Ambient Terminal Navigation & Audit Session (`caps` token audit -> `whereami` location -> bare `..` navigation -> clean `:q` exit)

---

### Tier 5: Adversarial Coverage Hardening (20 Tests)
- `[T5-ADV-01]` Tier 5 Specification Present
- `[T5-ADV-02]` Pipe Stream Clean Isolation (suppresses dock/prompt/badges in pipes)
- `[T5-ADV-03]` Multi-Hop Navigation Traversal (`...` parent jump)
- `[T5-ADV-04]` Bare `cd` Expands Home
- `[T5-ADV-05]` Failed `cd` Preserves Working Directory
- `[T5-ADV-06]` Varlink Error Method JSON Escaping
- `[T5-ADV-07]` Varlink Interface Error Escaping
- `[T5-ADV-08]` Varlink Multiline JSON Method Parsing
- `[T5-ADV-09]` Daemon Multi-Threaded Client Handling
- `[T5-ADV-10]` Daemon SIGINT Socket Clean Unlink
- `[T5-ADV-11]` Output Redirection (`>`) Gated From SAFE
- `[T5-ADV-12]` Command Chaining (`&&`) Gated From SAFE
- `[T5-ADV-13]` File Overwrite Redirection Gated From SAFE
- `[T5-ADV-14]` Tab-Delimited Destructive Filter (`rm\t`) HIGH_RISK Gating
- `[T5-ADV-15]` Tab-Delimited Destructive Filter (`delete\t`) HIGH_RISK Gating
- `[T5-ADV-16]` Interactive Edit Re-Evaluates Safety & YES Gate
- `[T5-ADV-17]` CRLF Line Sanitization
- `[T5-ADV-18]` Stdin EOF Clean Termination
- `[T5-ADV-19]` Bare `?` Disambiguation to Builtin Help
- `[T5-ADV-20]` Rapid Sequential Command Churn Resilience

---

## Exhaustive House Laws Audit Certification

1. **Page Rule (16–256 lines)**:
   - Command: `make line-cap`
   - Files checked: 51 total source and test files (`*.oo` and `*.oot`)
   - Floor: 17 lines (`./job/anchor.oo`)
   - Ceiling: 255 lines (`./dispatch.oo`)
   - Violations: **0**
   - Status: **PASS**

2. **Directory Density (<= 8 `.oo` files per directory, root exactly 8)**:
   - Root directory (`.`): **8 `.oo` files** (`alias.oo`, `anchor.oo`, `dispatch.oo`, `engine.oo`, `main.oo`, `manual.oo`, `prompt.oo`, `version.oo`)
   - `ui/`: 5 `.oo` files
   - `flight/`: 5 `.oo` files
   - `intent/`: 6 `.oo` files
   - `ipc/`: 3 `.oo` files
   - `diagnostics/`: 1 `.oo` file
   - `term/`: 6 `.oo` files
   - `syntax/`: 5 `.oo` files
   - `exec/`: 3 `.oo` files
   - `job/`: 3 `.oo` files
   - Violations: **0**
   - Status: **PASS**

3. **Academy Docstrings (4-element header in lines 1–7)**:
   - Required elements: `// # <Title>`, `// Logline:`, `// Setup:`, `// Beats:`
   - Files checked: 45 `.oo` files
   - Violations: **0**
   - Status: **PASS**

4. **File Law (Forbidden extensions & unpermitted files)**:
   - Command: `make file-law`
   - Prohibited extensions (`.py`, `.js`, `.ts`, `.rb`, `.pl`, `.json`, `.yaml`, `.toml`): 0 found outside `.git` / `.agents`
   - Allowed `.sh`: strictly `install.sh`
   - Allowed `.md`: strictly `README.md`, `AGENTS.md`, and `TEST_READY.md`
   - Violations: **0**
   - Status: **PASS**

5. **Type Checking (`oodac check`)**:
   - Command: `make check`
   - Files type-checked: 45 `.oo` files
   - Violations: **0**
   - Status: **PASS**

---
*Certified by Milestone 4 Quality Certification Worker (0808ee52-4676-4c4e-aebf-3b62501b1999).*
