# oosh

> **openOODA Sovereign Shell**  
> *The intent-driven, ambient, capability-bounded interactive shell for the AI era.*

Part of [openOODA-tools](https://github.com/openOODA-tools).

---

## 1. Quick Install (Any Linux Machine)

Install `oosh` on any Linux machine (x86_64 / aarch64) with zero dependencies. Neither `openOODA` nor `syntropd` is required on the host:

```bash
curl -fsSL https://raw.githubusercontent.com/openOODA-tools/oosh/main/install.sh | bash
```

The installer verifies cryptographic SHA-256 checksums, places the binary in `/usr/local/bin` (or `~/.local/bin`), and tests execution.

### Options
```bash
# Preview actions without modifying the host
curl -fsSL https://raw.githubusercontent.com/openOODA-tools/oosh/main/install.sh | bash -s -- --dry-run

# Uninstall
curl -fsSL https://raw.githubusercontent.com/openOODA-tools/oosh/main/install.sh | bash -s -- --uninstall
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

## 3. Build From Source

```bash
git clone git@github.com:openOODA-tools/oosh.git
cd oosh

# Build, verify, and test
make all

# Install locally
make install
```

---

## 4. Verification & Governance

All code adheres strictly to the openOODA House Laws documented in [`AGENTS.md`](AGENTS.md):
- **Page Rule**: Every source file strictly bounded between 16 and 256 lines.
- **Academy Headers**: Mandatory 4-element ASD-STE100 docstrings on every page.
- **Zero-Panic Invariant**: Robust error propagation without unvetted crashes.
- **File Law**: Clean tree with no forbidden file extensions or stray docs.