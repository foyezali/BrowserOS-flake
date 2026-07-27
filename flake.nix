{
  description = "BrowserOS — open-source agentic Chromium fork, packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        # AppImage doesn't carry a version string — BrowserOS is on a rolling beta.
        # When updating the AppImage, also bump `src.sha256` below.
        # Get the new hash with:  nix-prefetch-url --type sha256 <url>
        src = pkgs.fetchurl {
          url = "https://files.browseros.com/download/BrowserOS.AppImage";
          sha256 = "1fxvmsv26vpfn5m3yzwigpby4dfqfhx4mbd277s1ykvi6i3w8plg";
        };

        browseros = pkgs.appimageTools.wrapType2 {
          name = "browseros";
          pname = "browseros";
          version = "rolling";
          inherit src;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          # Chromium runtime libs not bundled in the AppImage
          extraPkgs = epkgs: with epkgs; [
            libudev0-shim
            libusb1
            openssl
            nss
            nspr
            alsa-lib
            pulseaudio
            gtk3
            cups
            libxshmfence
            libxkbcommon
            libXdamage
            libXrandr
            mesa
            wayland
            dbus
            libglvnd
          ];

          extraInstallCommands = ''
                        # Enable hardware video acceleration (VA-API) on Intel GPUs
                        wrapProgram $out/bin/browseros \
                          --add-flags "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks" \
                          --add-flags "--disable-gpu-driver-bug-workarounds" \
                          --add-flags "--disable-gpu-sandbox"

                        # Desktop entry
                        mkdir -p $out/share/applications
                        cat > $out/share/applications/browseros.desktop <<'EOF'
            [Desktop Entry]
            Name=BrowserOS
            Exec=browseros %U
            Type=Application
            Icon=browseros
            Categories=Network;WebBrowser;
            MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
            EOF

                        # Icon (extracted from AppImage by wrapType2)
                        if [ -f $out/lib/browseros/browseros.png ]; then
                          install -Dm644 $out/lib/browseros/browseros.png $out/share/pixmaps/browseros.png
                        fi
          '';

          meta = with lib; {
            description = "BrowserOS — open-source agentic Chromium fork";
            longDescription = ''
              BrowserOS is an open-source Chromium fork with a built-in AI agent.
              It is a privacy-first alternative to ChatGPT Atlas, Perplexity Comet,
              and Dia. This package wraps the upstream AppImage for Nix/NixOS.
            '';
            homepage = "https://www.browseros.com";
            license = licenses.agpl3Only;
            sourceProvenance = with sourceTypes; [ binaryNativeCode ];
            platforms = [ "x86_64-linux" ];
            mainProgram = "browseros";
          };
        };
      in
      {
        packages.default = browseros;
        packages.browseros = browseros;

        apps.browseros = {
          type = "app";
          program = "${browseros}/bin/browseros";
          meta = with lib; {
            description = "BrowserOS — open-source agentic Chromium fork";
            mainProgram = "browseros";
          };
        };
        apps.default = self.apps.${system}.browseros;

        # For the Go CLI sidecar (terminal control from agents like Claude Code)
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.go ];
          shellHook = ''
            echo "→ install CLI: go install github.com/browseros-ai/BrowserOS/apps/cli/cmd/browseros-cli@latest"
          '';
        };
      }
    );
}