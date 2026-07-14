#!/usr/bin/env bash
set -euo pipefail

# Update the BrowserOS AppImage hash in flake.nix.
# Run this whenever upstream updates the unversioned AppImage URL.

URL="https://files.browseros.com/download/BrowserOS.AppImage"

echo "Fetching new hash for $URL ..."
NEW_HASH=$(nix-prefetch-url --type sha256 "$URL")
echo "New sha256: $NEW_HASH"

# Verify the sed pattern will actually match before running it.
if ! grep -qE 'sha256 = "[0-9a-z]{52}";' flake.nix; then
  echo "ERROR: could not find a sha256 line in flake.nix matching the expected pattern." >&2
  exit 1
fi

# sed -i would be a no-op silently if the pattern didn't match; use a guarded
# substitution so a missing pattern is loud rather than silent.
before_hash=$(grep -oE 'sha256 = "[0-9a-z]{52}"' flake.nix)
sed -i.bak "s|sha256 = \"[0-9a-z]\{52\}\"|sha256 = \"$NEW_HASH\"|" flake.nix
rm flake.nix.bak

after_hash=$(grep -oE 'sha256 = "[0-9a-z]{52}"' flake.nix)
if [ "$before_hash" = "$after_hash" ]; then
  echo "ERROR: sed did not change the hash; file format may have shifted." >&2
  exit 1
fi

echo "Updated flake.nix: $before_hash -> $after_hash"
echo "Review the diff and commit when ready."
