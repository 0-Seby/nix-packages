#!/usr/bin/env bash
# Translate the bash env cache to fish syntax. Only variables are
# translated; bash functions and aliases don't apply to fish.
#
# Inputs: $out (current derivation's output path)
set -euo pipefail

# 1) `declare -x FOO="bar"` -> `set -gx FOO "bar"`
# 2) PATH is a list in fish, not a colon-string
@sed@ -n \
    -e 's|^declare -x \([A-Za-z_][A-Za-z0-9_]*\)="\(.*\)"$|set -gx \1 "\2"|p' \
    "$out/etc/openfoam-env.sh" \
  | @sed@ \
    -e 's|^set -gx PATH "\(.*\)"$|set -gx PATH (string split ":" "\1")|' \
    -e 's|^set -gx LD_LIBRARY_PATH "\(.*\)"$|set -gx LD_LIBRARY_PATH (string split ":" "\1")|' \
    > "$out/etc/openfoam-env.fish"
