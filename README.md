# BrowserOS-flake

Nix flake packaging the upstream [BrowserOS](https://github.com/browseros-ai/BrowserOS) AppImage.

## Install

### One-shot via Nix profile

```bash
nix profile install github:foyezali/BrowserOS-flake
browseros
```

### Reproducible pinned build

```bash
nix build github:foyezali/BrowserOS-flake#default
./result/bin/browseros
```

Or just:

```bash
nix build github:foyezali/BrowserOS-flake
./result/bin/browseros
```

### Inside a flake-based NixOS / home-manager configuration

```nix
{
  inputs.browseros-flake.url = "github:foyezali/BrowserOS-flake";

  outputs = { self, nixpkgs, home-manager, browseros-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [{
          home.packages = [ browseros-flake.packages.${system}.default ];
        }];
      };
    };
}
```

For NixOS:

```nix
{ inputs, pkgs, ... }: {
  environment.systemPackages = [ inputs.browseros-flake.packages.${pkgs.system}.default ];
}
```

### Develop locally

```bash
git clone https://github.com/foyezali/BrowserOS-flake.git
cd BrowserOS-flake
nix build          # or: nix run
```

## Updating the AppImage hash

BrowserOS doesn't version their AppImage URL. When changed:

```bash
./update.sh
```

## What's inside

- `flake.nix` — wraps the upstream AppImage with `appimageTools.wrapType2`
- `flake.lock` — run `nix flake lock` locally to pin inputs for reproducible builds
- `src.sha256` is pinned so the AppImage download is reproducible
- `--no-sandbox` flag added because Chromium's SUID sandbox can't run from `/nix/store`
- Desktop entry + icon extracted from the AppImage
- `meta` attributes for `nix search`, license tracking, and `mainProgram`
- `update.sh` helper to refresh the AppImage hash

## Companion CLI (optional)

BrowserOS has a Go CLI for terminal/MCP control. Spin up a shell with Go available:

```bash
nix develop
go install github.com/browseros-ai/BrowserOS/apps/cli/cmd/browseros-cli@latest
browseros-cli init
```


## License

The Nix packaging files in this repository are licensed under the MIT License. See [LICENSE](./LICENSE).

BrowserOS itself is licensed under the AGPL-3.0 license. See [browseros-ai/BrowserOS](https://github.com/browseros-ai/BrowserOS).
