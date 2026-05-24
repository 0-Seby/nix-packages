#!/usr/bin/env bash
# verify-cache.sh — confirm every flake output is fetchable from cachix.
set -euo pipefail

CACHE_URL="${CACHE_URL:-https://seby.cachix.org}"
SYSTEM="$(nix eval --impure --raw --expr 'builtins.currentSystem')"

echo ">>> Checking ${CACHE_URL} for outputs of ${SYSTEM} ..."

mapfile -t PKGS < <(
  nix eval --json ".#packages.${SYSTEM}" --apply 'builtins.attrNames' \
    | jq -r '.[]'
)

missing=()
for p in "${PKGS[@]}"; do
  out="$(nix eval --raw ".#packages.${SYSTEM}.${p}")"
  hash="$(basename "$out" | cut -d- -f1)"
  if curl -fsI -o /dev/null "${CACHE_URL}/${hash}.narinfo"; then
    printf '  \033[32m✓\033[0m %-24s %s\n' "$p" "$out"
  else
    printf '  \033[31m✗\033[0m %-24s %s  NOT in cache\n' "$p" "$out"
    missing+=("$p")
  fi
done

echo
if [[ ${#missing[@]} -eq 0 ]]; then
  echo "All ${#PKGS[@]} packages present."
else
  echo "Missing ${#missing[@]}/${#PKGS[@]}: ${missing[*]}"
  exit 1
fi
