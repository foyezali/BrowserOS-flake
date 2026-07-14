#!/usr/bin/env bash
set -euo pipefail

# Update the BrowserOS AppImage hash in flake.nix.
# Run this whenever upstream updates the unversioned AppImage URL.

URL="https://files.browseros.com/download/BrowserOS.AppImage"

echo "Fetching new hash for $URL ..."
NEW_HASH=$(nix-prefetch-url --type sha256 "$URL")
echo "New sha256: $NEW_HASH"

sed -i "s|sha256 = \"[^\"]*\";|sha256 = \"$NEW_HASH\";|" flake.nix
echo "Updated flake.nix."
