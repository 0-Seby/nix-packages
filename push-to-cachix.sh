#!/usr/bin/env bash
# push-to-cachix.sh — build all flake packages and push their closures to cachix.
set -euo pipefail

CACHE_NAME="${CACHE_NAME:-seby}"

command -v nix    >/dev/null || { echo "error: nix not on PATH";    exit 1; }
command -v cachix >/dev/null || { echo "error: cachix not on PATH"; exit 1; }

if [[ -z "${CACHIX_AUTH_TOKEN:-}" ]] && [[ ! -f "$HOME/.config/cachix/cachix.dhall" ]]; then
  echo "error: no cachix credentials"
  echo "  set CACHIX_AUTH_TOKEN=... or run: cachix authtoken <token>"
  exit 1
fi

SYSTEM="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
echo ">>> System: ${SYSTEM}"
echo ">>> Cache:  ${CACHE_NAME}"

# Build .#all — the linkFarm contains every per-system package output, so we
# only need one derivation reference for both build and push.
echo ">>> Building .#all ..."
ALL_OUT="$(nix build --no-link --print-out-paths ".#all")"
echo "    → ${ALL_OUT}"

# Runtime closure: what users actually need to substitute.
echo ">>> Pushing runtime closure ..."
nix path-info --recursive "$ALL_OUT" | cachix push "$CACHE_NAME"

# Build-time closure: lets incremental edits that don't change the runtime
# closure still hit cache for intermediate steps.
echo ">>> Pushing build-time (.drv) closure ..."
ALL_DRV="$(nix path-info --derivation ".#all")"
nix-store --query --requisites --include-outputs "$ALL_DRV" \
  | cachix push "$CACHE_NAME"

echo ">>> Done."
