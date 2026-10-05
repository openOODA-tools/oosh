# oosh DNF / RPM Package

This directory contains the RPM packaging specifications and installer for `oosh` (openOODA Sovereign Shell).

## Direct Installation via DNF

Install the official v1.0.0 RPM release directly using DNF:

```bash
sudo dnf install -y https://github.com/openOODA-tools/oosh/releases/download/v1.0.0/oosh-1.0.0-1.x86_64.rpm
```

Or using the unified installer:

```bash
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --dnf
```

## Local Build & Installation

To build and install the RPM locally from source:

```bash
make rpm
sudo dnf install -y dist/oosh-1.0.0-1.x86_64.rpm
```
