#!/usr/bin/env bash
# Symlink every OpenFOAM tool from $out/platforms/<wm-options>/bin
# into $out/bin so they appear on PATH without users needing
# the platform suffix on PATH directly.
#
# Inputs: $out, $WM_OPTIONS
set -euo pipefail

shopt -s nullglob
for entry in "$out/platforms/$WM_OPTIONS/bin"/*; do
    [ -f "$entry" ] && [ -x "$entry" ] || continue
    name="$(basename "$entry")"
    if [ ! -e "$out/bin/$name" ]; then
        ln -s "../platforms/$WM_OPTIONS/bin/$name" "$out/bin/$name"
    fi
done
