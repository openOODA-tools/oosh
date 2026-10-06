# oosh

> **openOODA Sovereign Shell**  
> *The intent-driven, ambient, capability-bounded interactive shell for the AI era.*

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/openOODA-tools/oosh/releases/tag/v1.0.0)
[![CI/CD](https://github.com/openOODA-tools/oosh/actions/workflows/ci.yml/badge.svg)](https://github.com/openOODA-tools/oosh/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)
[![Parity](https://img.shields.io/badge/POSIX%20Parity-10%2F10-brightgreen.svg)](#5-posix-parity--core-ergonomics)

Part of [openOODA-tools](https://github.com/openOODA-tools). Visit the [Official Landing Page](https://openooda-tools.github.io/oosh/).

---

## 1. Quick Install Matrix

`oosh` offers zero-dependency installation across all major Linux distributions via Web, DNF (RPM), APT (DEB), and Pacman (Arch/Omarchy) channels:

| Distribution Channel | Command | Description |
| :--- | :--- | :--- |
| **Web (Universal)** | `curl -fsSL https://openooda-tools.github.io/oosh/install.sh \| bash` | Direct glibc-linked standalone binary deployment with SHA-256 seal verification. |
| **DNF / RPM (Fedora/RHEL)** | `curl -fsSL https://openooda-tools.github.io/oosh/install.sh \| bash -s -- --dnf` | Native `.rpm` package installation via system `dnf` or `rpm`. |
| **APT / DEB (Ubuntu/Debian)** | `curl -fsSL https://openooda-tools.github.io/oosh/install.sh \| bash -s -- --apt` | Native `.deb` package installation via system `apt` or `dpkg`. |
| **Pacman (Arch/Omarchy)** | `curl -fsSL https://openooda-tools.github.io/oosh/install.sh \| bash -s -- --pacman` | Native Arch `.pkg.tar.zst` package installation via `pacman -U`. |
| **PKGBUILD (makepkg)** | `curl -fsSL https://openooda-tools.github.io/oosh/install.sh \| bash -s -- --pkgbuild` | Builds and installs via native Arch `PKGBUILD` and `makepkg -si`. |
| **Auto-Detect** | `curl -fsSL https://openooda-tools.github.io/oosh/install.sh \| bash -s -- --auto` | Automatically detects package manager (`dnf`, `apt`, or `pacman`), falling back to Web binary. |

### Direct Package Installation

You can also install packages directly from GitHub Releases:

```bash
# Arch Linux / Omarchy (Pacman)
sudo pacman -U https://github.com/openOODA-tools/oosh/releases/download/v1.0.0/oosh-1.0.0-1-x86_64.pkg.tar.zst

# Arch Linux / Omarchy (PKGBUILD / makepkg)
curl -fsSL -O https://openooda-tools.github.io/oosh/packaging/pacman/PKGBUILD
makepkg -si

# Fedora / RHEL / CentOS (RPM via DNF)
sudo dnf install -y https://github.com/openOODA-tools/oosh/releases/download/v1.0.0/oosh-1.0.0-1.x86_64.rpm

# Ubuntu / Debian (DEB via APT)
curl -fsSL -O https://github.com/openOODA-tools/oosh/releases/download/v1.0.0/oosh_1.0.0-1_amd64.deb
sudo apt install -y ./oosh_1.0.0-1_amd64.deb
rm -f oosh_1.0.0-1_amd64.deb
```

### Installer Options
```bash
# Preview actions without modifying the host
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --dry-run

# Verify cryptographic SHA-256 integrity only
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --verify

# Clean uninstall (removes package or binary)
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --uninstall
```

### Configuring Default Login Shell Safely

Depending on your Linux environment, configure `oosh` as your primary shell using the appropriate method:

#### 1. Standard Linux (`chsh`)
For system-wide installations (`/usr/local/bin/oosh` or `/usr/bin/oosh`) on standard systems:
```bash
# Verify shell is registered in /etc/shells (handled automatically by RPM/DEB/installer)
grep -q "^/usr/local/bin/oosh$" /etc/shells || echo "/usr/local/bin/oosh" | sudo tee -a /etc/shells

# Set default login shell
chsh -s /usr/local/bin/oosh
```

#### 2. systemd-homed Managed Accounts (`homectl`)
On modern systems utilizing `systemd-homed` with encrypted user homes (e.g. LUKS per-user storage):
```bash
# Update user account shell via homectl
homectl update "$USER" --shell=/usr/local/bin/oosh
```
> [!WARNING]
> **Encrypted Homes & Remote SSH Access**: On systems using `systemd-homed`, LUKS per-user encryption, or ecryptfs, the user's home directory is unmounted while logged out. Setting a shell binary inside `/home/` (such as `~/.local/bin/oosh`) causes login/SSH authentication failures (`systemd-home-fallback-shell` failure) because the binary does not exist on disk before authentication! Always install to a system-wide path (`/usr/local/bin/oosh` or `/usr/bin/oosh`), or use the `~/.bashrc` chaining method below.

#### 3. User-Local Installs & Safe Interactive Exec Chaining (`~/.bashrc`)
If installed without root privileges into `~/.local/bin`, or to safely launch `oosh` without altering system login accounts:
Keep `/bin/bash` or `/bin/zsh` as your login shell and append the following exec-chaining hook to the end of your `~/.bashrc` (or `~/.zshrc`):

```bash
if [[ $- == *i* ]] && [ -x /usr/local/bin/oosh ] && [ "$OOSH_ACTIVE" != "1" ]; then
    export OOSH_ACTIVE=1
    exec /usr/local/bin/oosh
fi
```
*(If installed locally to `~/.local/bin`, replace `/usr/local/bin/oosh` with `"$HOME/.local/bin/oosh"`).*
This ensures non-interactive SSH commands, scp/rsync, and display managers retain standard shell behavior while interactive terminal sessions seamlessly enter `oosh`.

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
| **`alias [k=v]`** | Environment | `aliases` | Registers or lists dynamic command aliases (`alias ll='ls -la'`). |
| **`unalias <k>`** | Environment | `unset-alias`, `rmalias` | Removes registered dynamic command alias. |
| **`export <k=v>`** | Environment | `setenv` | Sets session environment variables inherited by child processes. |
| **`unset <key>`** | Environment | `unsetenv` | Unsets session environment variables. |
| **`remedy`** | Repair | `fix`, `repair`, `heal`, `patch`, `resolve`, `cure`, `undo` | Inspects recent error context and proposes diagnostics. |
| **`? <query>`** | Intent Channel | `??`, `ai`, `ask`, `do`, `how`, `why`, `please` | Channels natural language intent to reasoning engine. |
| **`<binary>`** | Host Execution | Any host executable (`ls`, `git`, `cargo`, `ps`, `uname`, etc.) | Direct host process execution scoped to active cwd under `&ProcessCap`. |

---

## 4. Proactive Threat Defenses

`oosh` implements 5 proactive, architectural defenses against traditional and emerging shell attack vectors:

1. **Terminal Escape Sequence & Input Injection (OSC 52 / CSI 6n)**:
   - *Threat*: Malicious output or clipboard responses injecting carriage returns and shell commands via unsolicited terminal query replies.
   - *Defense*: Typed raw TUI input event decoding in `term/read.oo`. Keystrokes are strictly distinguished from terminal query replies (`CSI ... R`, `CSI ... c`, and `OSC` sequences), isolating and routing query responses without buffer pollution.
2. **Wildcard & Glob Argument Injection (`-*` Filenames)**:
   - *Threat*: Files starting with `-` (e.g., `-rf`, `--help`) being expanded by wildcards (`*`) into flags for destructive commands like `rm *`.
   - *Defense*: In `syntax/glob.oo`, filename matches starting with `-` are normalized to `./-*`. In `intent/safety.oo`, dangerous glob operations on mutation/destructive builtins are classified as `HIGH_RISK` and gated.
3. **Control Socket Isolation & Peer Credential Authentication**:
   - *Threat*: Bare control sockets in `/tmp/` vulnerable to symlink hijacking, hijacking by co-located users, or unauthenticated RPC invocation.
   - *Defense*: Daemon sockets in `ipc/daemon.oo` resolve to private `/tmp/oosh-$UID/` directories locked to `0700` permissions. Connecting clients undergo kernel-enforced `SO_PEERCRED` validation, strictly ensuring the client UID matches `getuid()`.
4. **Parser Stack Exhaustion Ceilings (Parser Bombs)**:
   - *Threat*: Adversarial inputs with thousands of nested parentheses or control structures triggering thread stack overflows (SIGSEGV).
   - *Defense*: Deterministic recursion limits (`depth < 128`) in `syntax/arith.oo` and `syntax/control.oo`. Deeply nested expression bombs are cleanly rejected with descriptive syntax errors.
5. **Stream Ingestion Quotas**:
   - *Threat*: Piping infinite streams (e.g., `/dev/zero`, multi-gigabyte log dumps) into shell property extractors or filters exhausting heap memory.
   - *Defense*: A strict 16MB stream ingestion ceiling in `exec/stream.oo` for property access (`.field`) and tabular filtering (`where`). Breached streams are cleanly truncated with exit status 137 and diagnostic autopsy telemetry in `flight/envelope.oo`.

---

## 5. POSIX Parity & Core Ergonomics

`oosh` balances strict capability security with deep POSIX and developer familiarity:
- **In-Process Group Redirection**: `{ cmd1; cmd2; } > output.txt` executes in-process, preserving environment and session variable mutations while cleanly redirecting combined output.
- **Subshell Environment Retention**: Full environment map propagation into subshells (`$(...)`) and backticks while filtering hazardous read-only/ambient variables.
- **Unary File System Tests**: In-memory, capability-bounded evaluation of `-e`, `-f`, `-d`, and `-s` unary operators under `FsReadCap`.
- **Native Job Control**: Complete job tracking with `jobs`, `fg`, `bg`, and native `wait` builtin (supporting wait-all, job spec `%N`, or specific PID).
- **Quoted Glob Preservation**: Proper distinction between literal quoted patterns (`"*.oo"`) and expandable unquoted patterns (`*.oo`).

---

## 6. Clean Unthemed Terminal Posture

In keeping with Unix philosophy and openOODA lean architecture:
- `oosh` relies entirely on standard **16-color ANSI SGR primitives** in `ui/palette.oo`.
- All heavy theme tables, 24-bit TrueColor hex parsers, and custom color configuration overhead have been stripped out.
- The shell stays lean, fast, robust, and universally readable across any terminal emulator, serial console, or remote SSH session.
- Advanced styling and thematic customization are decoupled into a dedicated companion engine (`oote`).

---

## 7. Build & Packaging From Source

```bash
git clone git@github.com:openOODA-tools/oosh.git
cd oosh

# Build native binary dist/oosh
make build

# Build native Linux RPM package (dist/oosh-1.0.0-1.x86_64.rpm)
make rpm

# Build native Debian/Ubuntu DEB package (dist/oosh_1.0.0-1_amd64.deb)
make deb

# Build both RPM and DEB packages
make pkg

# Build, verify, and run all test suites (unit + smoke + E2E tiers 1-5)
make all

# Install locally to ~/.openooda/bin/oosh
make install
```

Package specifications and helper scripts reside in [`packaging/dnf/`](packaging/dnf/) and [`packaging/apt/`](packaging/apt/).

---

## 8. Verification & Governance

All code adheres strictly to the openOODA House Laws documented in [`AGENTS.md`](AGENTS.md):
- **Page Rule**: Every source file strictly bounded between 16 and 256 lines.
- **Academy Headers**: Mandatory 4-element ASD-STE100 docstrings on every page.
- **Zero-Panic Invariant**: Robust error propagation without unvetted crashes.
- **File Law**: Clean tree with no forbidden file extensions or stray docs.