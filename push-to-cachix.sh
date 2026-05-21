#!/usr/bin/env bash
# push-to-cachix.sh — build every flake package and push it (plus runtime deps) to cachix.
# Run only when you actually want to upload.
 
set -euo pipefail
 
CACHE_NAME="${CACHE_NAME:-seby}"
 
# Sanity checks
command -v nix    >/dev/null || { echo "error: nix not on PATH"; exit 1; }
command -v cachix >/dev/null || { echo "error: cachix not on PATH (try: nix profile install nixpkgs#cachix)"; exit 1; }
 
# Auth check — needs CACHIX_AUTH_TOKEN env var OR a prior `cachix authtoken <token>`
if [[ -z "${CACHIX_AUTH_TOKEN:-}" ]] && [[ ! -f "$HOME/.config/cachix/cachix.dhall" ]]; then
  echo "error: no cachix credentials found"
  echo "  set CACHIX_AUTH_TOKEN=... or run: cachix authtoken <token-from-app.cachix.org>"
  exit 1
fi
 
echo ">>> Discovering packages in flake..."
# Read all attribute names under packages.<system> directly from the flake
SYSTEM="$(nix eval --impure --raw --expr 'builtins.currentSystem')"
mapfile -t PKGS < <(nix eval --json ".#packages.${SYSTEM}" --apply 'builtins.attrNames' | jq -r '.[]')
 
if [[ ${#PKGS[@]} -eq 0 ]]; then
  echo "error: no packages found in flake"
  exit 1
fi
 
echo ">>> Will build and push ${#PKGS[@]} packages: ${PKGS[*]}"
 
# Build all of them. Already-built paths are no-ops.
echo ">>> Building..."
BUILD_ARGS=()
for p in "${PKGS[@]}"; do
  BUILD_ARGS+=(".#${p}")
done
# --no-link avoids creating result-* symlinks in CWD
OUTPATHS=$(nix build --no-link --print-out-paths "${BUILD_ARGS[@]}")
 
# Compute full runtime closure of every output and push the union
echo ">>> Computing runtime closure and pushing to cachix:${CACHE_NAME}..."
echo "$OUTPATHS" | xargs nix path-info --recursive | cachix push "$CACHE_NAME"
 
echo ">>> Done."
 

