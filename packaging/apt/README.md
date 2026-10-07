# oosh APT / DEB Package

This directory contains the Debian/Ubuntu packaging specifications and installer for `oosh` (openOODA Sovereign Shell).

## Direct Installation via APT

Install the official v1.0.1 Debian package directly:

```bash
curl -fsSL -O https://github.com/openOODA-tools/oosh/releases/download/v1.0.1/oosh_1.0.1-1_amd64.deb
sudo apt install -y ./oosh_1.0.1-1_amd64.deb
rm -f oosh_1.0.1-1_amd64.deb
```

Or using the unified installer:

```bash
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --apt
```

## Local Build & Installation

To build and install the Debian package locally from source:

```bash
make deb
sudo apt install -y ./dist/oosh_1.0.1-1_amd64.deb
```
