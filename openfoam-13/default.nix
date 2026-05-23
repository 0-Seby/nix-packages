{
  lib,
  stdenv,
  fetchFromGitHub,
  removeReferencesTo,
  autoPatchelfHook,
  bash,
  bison,
  boost,
  cgal,
  fftw,
  flex,
  gnum4,
  mpi,
  scotch,
  trilinos-mpi,
  zlib,
  paraview,
  gnuplot,
  cmake,
  qt6,
  vtk,
  coreutils,
  findutils,
  gawk,
  gnused,
  gnumake,
}:

let
  scotch-mpi = scotch.overrideAttrs (prev: {
    buildInputs = (prev.buildInputs or [ ]) ++ [ mpi ];
    cmakeFlags = (prev.cmakeFlags or [ ]) ++ [ "-DBUILD_PTSCOTCH=ON" ];
  });

  pvMajorMinor = lib.versions.majorMinor paraview.version;
in
stdenv.mkDerivation {
  pname = "openfoam";
  version = "13";

  src = fetchFromGitHub {
    owner = "OpenFOAM";
    repo = "OpenFOAM-13";
    rev = "refs/tags/version-13";
    hash = "sha256-Iics6mmxvxmhZWpkIwfooU6gBiEECfyH+R4mvJ0AtxM=";
  };

  nativeBuildInputs = [
    removeReferencesTo
    autoPatchelfHook
    bison
    flex
    gnum4
    cmake
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    bash
    boost
    cgal
    fftw
    mpi
    scotch-mpi
    trilinos-mpi
    zlib
    paraview
    gnuplot
    qt6.qtbase
    vtk
    coreutils
    findutils
    gawk
    gnused
    gnumake
  ];

  runtimeDependencies = [
    mpi
    scotch-mpi
  ];

  env.NIX_CFLAGS_COMPILE = "-I${vtk}/include/vtk -I${paraview}/include/paraview";

  postPatch = ''
    patchShebangs ./

    substituteInPlace etc/config.sh/aliases --replace-fail 'unalias ' 'unalias 2>/dev/null || true #'
    substituteInPlace etc/config.sh/unset --replace-fail 'unalias ' 'unalias 2>/dev/null || true #'

    substituteInPlace etc/bashrc \
      --replace-fail '[ "$BASH" ] && . $WM_PROJECT_DIR/etc/config.sh/bash_completion' \
                     'if [ -n "$BASH" ] && [[ $- == *i* ]]; then . $WM_PROJECT_DIR/etc/config.sh/bash_completion; fi'

    substituteInPlace etc/bashrc \
      --replace-fail 'export FOAM_INST_DIR=$(cd $(dirname $bashrcFile)/../.. && pwd -P)' \
                     'export FOAM_INST_DIR=''${FOAM_INST_DIR:-'${placeholder "out"}'}' \
      --replace-fail 'export WM_PROJECT_DIR=$WM_PROJECT_INST_DIR/$WM_PROJECT-$WM_PROJECT_VERSION' \
                     'export WM_PROJECT_DIR=''${WM_PROJECT_DIR:-'${placeholder "out"}'}'

    substituteInPlace bin/foamEtcFile \
      --replace-fail 'echo "Error : unknown/unsupported naming convention"' 'version="13"' \
      --replace-fail 'exit 1' ':'

    substituteInPlace applications/utilities/postProcessing/graphics/PVReaders/CMakeLists.txt \
      --replace-fail 'FIND_PACKAGE(ParaView REQUIRED)' \
      "FIND_PACKAGE(ParaView REQUIRED)

    set(CMAKE_SKIP_BUILD_RPATH TRUE)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH \"\")
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)"

    substituteInPlace etc/config.sh/mpi \
      --replace-fail 'mpicc' '${lib.getDev mpi}/bin/mpicc'

    substituteInPlace applications/utilities/postProcessing/graphics/PVReaders/Allwmake \
      --replace-fail 'if $WM_PROJECT_DIR/bin/tools/foamVersionCompare $ParaView_VERSION ge 5.7.0' 'if true'

    substituteInPlace etc/config.sh/paraview \
      --replace-fail 'ldd $paraviewBinDir/paraview' 'echo "${paraview}/lib/libpqCore-pv.so"'
  '';

  configurePhase = ''
    runHook preConfigure

    cat <<EOF >> etc/prefs.sh
    export SCOTCH_TYPE=system
    export ZOLTAN_TYPE=system
    export WM_MPLIB=SYSTEMOPENMPI

    export MPI_ARCH_PATH="${mpi}"
    export MPI_HOME="${mpi}"

    export ParaView_TYPE=system
    export ParaView_DIR="${paraview}"
    export ParaView_INCLUDE_DIR="${paraview}/include/paraview"
    export ParaView_LIB_DIR="${paraview}/lib"
    EOF

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    set -e

    export HOME="$TMPDIR"
    mkdir -p "$HOME"

    export WM_NCOMPPROCS="$NIX_BUILD_CORES"
    export FOAM_INST_DIR="$PWD"
    export WM_PROJECT_DIR="$PWD"
    
    source etc/bashrc

    export WM_CPPFLAGS="$NIX_CFLAGS_COMPILE"

    export PV_PLUGIN_PATH="$FOAM_LIBBIN/paraview-${pvMajorMinor}"
    mkdir -p "$PV_PLUGIN_PATH"

    make -C wmake/src CC=gcc
    ./Allwmake -j "$WM_NCOMPPROCS" -q

    echo "Building ParaView Readers..."
    ./applications/utilities/postProcessing/graphics/PVReaders/Allwmake -j "$WM_NCOMPPROCS"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    export FOAM_INST_DIR="$PWD"
    export WM_PROJECT_DIR="$PWD"
    source etc/bashrc

    mkdir -p "$out/bin" \
             "$out/etc" \
             "$out/tutorials" \
             "$out/jobControl" \
             "$out/site" \
             "$out/platforms/$WM_OPTIONS/bin" \
             "$out/platforms/$WM_OPTIONS/lib"

    cp -a bin/. "$out/bin/"
    cp -a etc/. "$out/etc/"
    cp -a tutorials/. "$out/tutorials/"
    cp -a wmake "$out/wmake"
    cp -a src "$out/src"
    cp -a applications "$out/applications"

    cp -a platforms/$WM_OPTIONS/bin/. "$out/platforms/$WM_OPTIONS/bin/"
    cp -a platforms/$WM_OPTIONS/lib/. "$out/platforms/$WM_OPTIONS/lib/"

    runHook postInstall
  '';

  postFixup = ''
    export FOAM_INST_DIR="$PWD"
    export WM_PROJECT_DIR="$PWD"
    source etc/bashrc

    remove-references-to -t ${cgal} $out/etc/config.sh/* 2>/dev/null || true

    echo "Installing OpenFOAM command symlinks..."
    shopt -s nullglob
    for entry in "$out/platforms/$WM_OPTIONS/bin"/*; do
      if [ -f "$entry" ] && [ -x "$entry" ]; then
        program_name="$(basename "$entry")"
        if [ ! -e "$out/bin/$program_name" ]; then
          ln -s "../platforms/$WM_OPTIONS/bin/$program_name" "$out/bin/$program_name"
        fi
      fi
    done

    # -------------------------------------------------------------------
    # Capture OpenFOAM's environment at build time so sourcing is fast.
    #
    # The upstream bashrc fork-execs hundreds of grep/sed/awk processes
    # to dedupe PATH and probe for config files. On Nix every spawn cold-
    # loads from /nix/store, which adds up to ~3 s per source. Since this
    # derivation is deterministic, we run the bashrc once here and replay
    # the result later with two cheap variable expansions.
    # -------------------------------------------------------------------

    echo "Capturing OpenFOAM environment..."

    fakeHome="$TMPDIR/of-cache-home"
    fakeUser="__OPENFOAM_CACHED_USER__"
    mkdir -p "$fakeHome"

    env -i \
      HOME="$fakeHome" \
      USER="$fakeUser" \
      LOGNAME="$fakeUser" \
      TERM=dumb \
      PATH="${lib.makeBinPath [ coreutils ]}" \
      ${bash}/bin/bash -c "
        set +u
        exec 2>/dev/null
        export FOAM_INST_DIR='$out'
        export WM_PROJECT_INST_DIR='$out'
        export WM_PROJECT_DIR='$out'
        export MPI_ARCH_PATH='${mpi}'
        export MPI_HOME='${mpi}'
        export PATH='$out/bin:${lib.makeBinPath [
          (lib.getDev mpi) mpi paraview gnuplot coreutils findutils gawk gnused gnumake stdenv.cc
        ]}'
        source '$out/etc/bashrc'
        export PV_PLUGIN_PATH='$out/platforms/'\"\$WM_OPTIONS\"'/lib/paraview-${pvMajorMinor}'

        printf '# --- exported variables ---\n'
        declare -px
        printf '\n# --- functions ---\n'
        declare -f
        printf '\n# --- aliases ---\n'
        alias -p
      " > "$TMPDIR/foam-env-raw.sh"

    ${gnused}/bin/sed \
      -e '/^declare -x HOME=/d' \
      -e '/^declare -x USER=/d' \
      -e '/^declare -x LOGNAME=/d' \
      -e '/^declare -x TERM=/d' \
      -e '/^declare -x PWD=/d' \
      -e '/^declare -x OLDPWD=/d' \
      -e '/^declare -x SHLVL=/d' \
      -e '/^declare -x _=/d' \
      -e "s|$fakeHome|\''${HOME}|g" \
      -e "s|$fakeUser|\''${USER}|g" \
      "$TMPDIR/foam-env-raw.sh" > "$out/etc/openfoam-env.sh"

    echo "Generating fast openfoam-init..."
    cat > "$out/bin/openfoam-init" <<INITEOF
# Fast OpenFOAM environment loader.
#
# The full OpenFOAM bashrc spawns hundreds of subprocesses for path
# manipulation, which costs ~3 s on Nix. We pre-compute its output at
# build time and store it in \$out/etc/openfoam-env.sh. This script
# replays that environment; only \$HOME and \$USER expand at runtime.
#
# Caveats:
#   * Configuration is baked in. Setting WM_COMPILE_OPTION, WM_MPLIB,
#     etc. before sourcing this has NO effect -- rebuild the derivation
#     to change them.
#   * Functions defined by the bashrc (foamEtcFile, foamCleanPath,
#     _foamAddPath, ...) remain available and work as before.

_of_prev_path="\''${PATH-}"
_of_prev_ld="\''${LD_LIBRARY_PATH-}"

source "$out/etc/openfoam-env.sh"

# Preserve the caller's pre-existing PATH/LD_LIBRARY_PATH after the
# OpenFOAM entries -- mirrors the original "prepend, don't replace" behaviour.
[ -n "\$_of_prev_path" ] && export PATH="\$PATH:\$_of_prev_path"
if [ -n "\$_of_prev_ld" ]; then
  export LD_LIBRARY_PATH="\''${LD_LIBRARY_PATH-}\''${LD_LIBRARY_PATH:+:}\$_of_prev_ld"
fi
unset _of_prev_path _of_prev_ld
INITEOF
    chmod +x "$out/bin/openfoam-init"

    echo "Generating dual-mode openfoam-shell entrypoint..."
    cat > "$out/bin/openfoam-shell" <<EOF
#!${bash}/bin/bash
set -euo pipefail

if [ \$# -eq 0 ]; then
    TMP_RC=\$(mktemp)
    echo "source \"$out/bin/openfoam-init\"" > "\$TMP_RC"
    echo "rm -f \"\$TMP_RC\"" >> "\$TMP_RC"
    exec ${bash}/bin/bash --noprofile --rcfile "\$TMP_RC" -i
else
    source "$out/bin/openfoam-init"
    exec "\$@"
fi
EOF
    chmod +x "$out/bin/openfoam-shell"
  '';
}
