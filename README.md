# oosh

> **openOODA Sovereign Shell**  
> *The intent-driven, ambient, capability-bounded interactive shell for the AI era.*

Part of [openOODA-tools](https://github.com/openOODA-tools).

---

## 1. Quick Install (Any Linux Machine)

Install `oosh` on any Linux machine (x86_64 / aarch64) with zero dependencies. Neither `openOODA` nor `syntropd` is required on the host:

```bash
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash
```

The installer verifies cryptographic SHA-256 checksums, places the binary in `/usr/local/bin` (or `~/.local/bin`), and tests execution.

### Options
```bash
# Preview actions without modifying the host
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --dry-run

# Uninstall
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --uninstall
```

---

## 2. Vision & Architecture

`oosh` is an interactive command plane engineered for direct systems control, ambient environment integration, and intent-driven computing:
- **Zero External Dependencies**: Pure glibc-linked standalone executable.
- **Capability-Bounded Authority**: Privileged execution requires unforgeable capability tokens (`openOODA`).
- **Native OS & Daemon Integration**: Interfaces with `syntropd` daemons (`contextd`, `toold`, `sentry`) over Varlink IPC when present.
- **Dual-Plane Execution**: Instant POSIX binary execution for everyday tooling (`cargo`, `git`, `systemctl`) paired with natural language intent translation.
- **Ambient Extension**: Designed to tether beyond the laptop screen to physical tokens (the Rune) and ambient sensory fields.

---

## 3. Builtin Commands, Aliases & Triggers

`oosh` bends to human muscle memory rather than punishing it:

| Canonical Command | Category | Aliases, Flags & Natural Triggers | Description & Behavior |
| :--- | :--- | :--- | :--- |
| **`help`** | Guidance | `-h`, `--help`, `?`, `/?`, `-?`, `man`, `manual`, `guide`, `docs`, `commands`, `what` | Opens help. Contextual if given a command (e.g. `help cd`). |
| **`exit`** | Session | `quit`, `q`, `:q`, `:q!`, `:x`, `bye`, `logout`, `leave`, `close` | Cleanly exits shell session and restores terminal state. |
| **`clear`** | Viewport | `cls`, `clean`, `reset`, `wipe`, `blank` | Wipes the terminal viewport and resets cursor position. |
| **`cd [dir]`** | Navigation | `chdir`, `goto`, `jump`, `walk`, `..` *(bare)*, `...` *(up 2)*, `-` | Changes working directory. Typing just `..` jumps up one level! |
| **`pwd`** | Navigation | `cwd`, `where`, `whereami`, `here`, `path` | Prints current working directory. `whereami` also shows git branch. |
| **`take <dir>`** | Ergonomics | `mkcd`, `mcd`, `mdcd`, `create-cd` | Atomically creates a nested directory (`mkdir -p`) and enters it. |
| **`open <file>`** | Ergonomics | `view`, `show`, `launch`, `xdg-open` | Opens target using desktop handler or default viewer. |
| **`time <cmd>`** | Performance | `bench`, `benchmark`, `measure`, `clock` | Measures wall-clock execution time and memory overhead. |
| **`caps`** | Capability Audit | `cap`, `capabilities`, `perms`, `permissions`, `tokens`, `authority`, `whoami` | Audits session's active unforgeable capability tokens (`ProcessCap`, etc.). |
| **`status`** | Telemetry | `stat`, `info`, `health`, `posture`, `ping`, `check`, `--status`, `-s` | Displays node health, openOODA runtime metrics, and `syntropd` status. |
| **`version`** | Identity | `-v`, `--version`, `-V`, `ver`, `banner`, `about`, `whoareyou` | Displays `oosh` version, compiler provenance, and startup banner. |
| **`hi`** | Conversational | `hello`, `hey`, `yo`, `greetings`, `howdy`, `sup`, `morning`, `evening` | Friendly acknowledgment confirming shell readiness. |
| **`autopsy`** | openOODA Law | `bb`, `blackbox`, `flight`, `crash`, `postmortem`, `triage`, `coroner` | Examines flight recorder log of crashes or faults. |
| **`rune [action]`** | Physical Ambient | `token`, `talisman`, `dongle`, `key`, `staff`, `haptic` | Checks or pairs cryptographic status from physical hardware tokens. |
| **`link [socket]`** | Multi-Node | `connect`, `sync`, `attach`, `bind`, `peer` | Links shell to local or remote `syntropd` Varlink IPC daemon. |
| **`scry [target]`** | Diagnostics | `inspect`, `probe`, `trace`, `reveal`, `peek`, `diagnose` | Deep-scans kernel/system state, memory churn, and load averages. |
| **`remedy`** | Repair | `fix`, `repair`, `heal`, `patch`, `resolve`, `cure`, `undo` | Inspects recent error context and proposes diagnostics. |
| **`? <query>`** | Intent Channel | `??`, `ai`, `ask`, `do`, `how`, `why`, `please` | Channels natural language intent to reasoning engine. |
| **`<binary>`** | Host Execution | Any host executable (`ls`, `git`, `cargo`, `ps`, `uname`, etc.) | Direct host process execution scoped to active cwd under `&ProcessCap`. |

---

## 4. Build From Source

```bash
git clone git@github.com:openOODA-tools/oosh.git
cd oosh

# Build, verify, and test
make all

# Install locally
make install
```

---

## 5. Verification & Governance

All code adheres strictly to the openOODA House Laws documented in [`AGENTS.md`](AGENTS.md):
- **Page Rule**: Every source file strictly bounded between 16 and 256 lines.
- **Academy Headers**: Mandatory 4-element ASD-STE100 docstrings on every page.
- **Zero-Panic Invariant**: Robust error propagation without unvetted crashes.
- **File Law**: Clean tree with no forbidden file extensions or stray docs.