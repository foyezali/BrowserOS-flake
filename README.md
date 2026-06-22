# BrowserOS-flake

Nix flake packaging the upstream [BrowserOS](https://github.com/browseros-ai/BrowserOS) AppImage.

BrowserOS is an open-source Chromium fork with built-in AI agents — alternative to ChatGPT Atlas / Perplexity Comet. License: **AGPL-3.0**.

## Install

### One-shot via Nix profile

```bash
nix profile install github:foyezali/BrowserOS-flake
browseros
```

### Reproducible pinned build

```bash
nix build github:foyezali/BrowserOS-flake#browseros
./result/bin/browseros
```

### Inside a NixOS configuration

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.callPackage (builtins.fetchTarball {
      url = "https://github.com/foyezali/BrowserOS-flake/archive/main.tar.gz";
    }) {}).default
  ];
}
```

Or with flakes + home-manager:

```nix
{
  inputs.browseros-flake.url = "github:foyezali/BrowserOS-flake";
  outputs = { self, nixpkgs, home-manager, browseros-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      home.packages = [ browseros-flake.packages.${system}.default ];
    };
}
```

### Develop locally

```bash
git clone https://github.com/foyezali/BrowserOS-flake.git
cd BrowserOS-flake
nix build          # or: nix run
```

On first build nix auto-generates `flake.lock`.

## Updating the AppImage hash

BrowserOS doesn't version their AppImage URL. When you want to bump:

```bash
nix-prefetch-url --type sha256 https://files.browseros.com/download/BrowserOS.AppImage
```

Paste the output into `src.sha256` in `flake.nix`.

## What's inside

- `flake.nix` — wraps the upstream AppImage with `appimageTools.wrapType2`
- `src.sha256` is pinned so the build is reproducible
- `--no-sandbox` flag added because Chromium's SUID sandbox can't run from `/nix/store`
- Desktop entry + icon extracted from the AppImage

## Companion CLI (optional)

BrowserOS has a Go CLI for terminal/MCP control. Spin up a shell with Go available:

```bash
nix develop
go install github.com/browseros-ai/BrowserOS/apps/cli/cmd/browseros-cli@latest
browseros-cli init
```

## NixOS gotchas handled

| Issue | Fix |
|---|---|
| Chromium SUID sandbox can't run from `/nix/store` | `--no-sandbox` flag |
| AppImage needs FUSE | `wrapType2` extracts the squashfs → no FUSE needed |
| Missing .so files (nss, nspr, gtk, mesa, etc.) | `extraPkgs` adds them to runtime closure |
| Desktop integration | Generated `.desktop` + icon in `share/` |