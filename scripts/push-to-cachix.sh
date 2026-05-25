#!/usr/bin/env bash
set -euo pipefail
CACHE_NAME="${CACHE_NAME:-seby}"

command -v cachix >/dev/null || { echo "need cachix"; exit 1; }
[[ -n "${CACHIX_AUTH_TOKEN:-}" ]] || [[ -f "$HOME/.config/cachix/cachix.dhall" ]] \
  || { echo "no cachix auth"; exit 1; }

echo ">>> watch-exec building .#all into ${CACHE_NAME}"
cachix watch-exec "$CACHE_NAME" -- \
  nix build --no-link --print-out-paths --keep-going ".#all"
echo ">>> done"
