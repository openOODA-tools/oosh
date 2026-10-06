# oosh Pacman / Arch Package & PKGBUILD

This directory contains the Arch Linux / Omarchy packaging specifications and installer for `oosh` (openOODA Sovereign Shell).

## Installation via Pacman (.pkg.tar.zst)

Install the official package directly using pacman:

```bash
sudo pacman -U https://github.com/openOODA-tools/oosh/releases/download/v1.0.0/oosh-1.0.0-1-x86_64.pkg.tar.zst
```

Or using the unified installer:

```bash
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --pacman
```

## Installation via PKGBUILD

To build and install via `makepkg` on Arch Linux or Omarchy:

```bash
cd packaging/pacman
makepkg -si
```

Or using the unified installer:

```bash
curl -fsSL https://openooda-tools.github.io/oosh/install.sh | bash -s -- --pkgbuild
```

## Local Build & Packaging

To generate the `.pkg.tar.zst` package locally:

```bash
make pacman
sudo pacman -U dist/oosh-1.0.0-1-x86_64.pkg.tar.zst
```
