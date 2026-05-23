#!/usr/bin/env bash
# Capture OpenFOAM's full environment by sourcing the slow bashrc once,
# dumping the resulting exports/functions/aliases to a file the runtime
# init scripts can replay in milliseconds. Placeholders are filled by
# replaceVars before this script reaches the store.
#
# Inputs: $out (current derivation's output path)
set -euo pipefail

fakeHome="$TMPDIR/of-cache-home"
fakeUser="__OPENFOAM_CACHED_USER__"
mkdir -p "$fakeHome"

# Source the bashrc inside a clean environment so nothing from the
# build sandbox leaks into the cache.
env -i \
    HOME="$fakeHome" \
    USER="$fakeUser" \
    LOGNAME="$fakeUser" \
    TERM=dumb \
    PATH="@coreutilsBin@" \
    @bash@ -c "
        set +u
        exec 2>/dev/null

        export FOAM_INST_DIR='@core@'
        export WM_PROJECT_INST_DIR='@core@'
        export WM_PROJECT_DIR='@core@'
        export MPI_ARCH_PATH='@mpiPrefix@'
        export MPI_HOME='@mpiPrefix@'
        export PATH='@core@/bin:@runtimePath@'

        source '@core@/etc/bashrc'

        # Re-pin so we control where ParaView plugins resolve from.
        export PV_PLUGIN_PATH='@core@/platforms/@wmOptions@/lib/paraview-@pvMajorMinor@'

        printf '# --- exported variables ---\n'
        declare -px
        printf '\n# --- functions ---\n'
        declare -f
        printf '\n# --- aliases ---\n'
        alias -p
    " > "$TMPDIR/foam-env-raw.sh"

# Strip caller-owned state and replace the build-time placeholders
# with shell variables that expand at source-time on the user's machine.
@sed@ \
    -e '/^declare -x HOME=/d' \
    -e '/^declare -x USER=/d' \
    -e '/^declare -x LOGNAME=/d' \
    -e '/^declare -x TERM=/d' \
    -e '/^declare -x PWD=/d' \
    -e '/^declare -x OLDPWD=/d' \
    -e '/^declare -x SHLVL=/d' \
    -e '/^declare -x _=/d' \
    -e "s|$fakeHome|\${HOME}|g" \
    -e "s|$fakeUser|\${USER}|g" \
    "$TMPDIR/foam-env-raw.sh" > "$out/etc/openfoam-env.sh"
