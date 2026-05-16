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

    echo "Generating standalone openfoam-shell entrypoint..."
    cat > "$out/bin/openfoam-shell" <<EOF
#!${bash}/bin/bash
set -euo pipefail

export FOAM_INST_DIR="$out"
export WM_PROJECT_INST_DIR="$out"
export WM_PROJECT_DIR="$out"
export MPI_ARCH_PATH="${mpi}"
export MPI_HOME="${mpi}"

export PV_PLUGIN_PATH="$out/platforms/$WM_OPTIONS/lib/paraview-${pvMajorMinor}"

export PATH="$out/bin:${lib.makeBinPath [
  (lib.getDev mpi)
  mpi
  paraview
  gnuplot
  coreutils
  findutils
  gawk
  gnused
  gnumake
  stdenv.cc
]}:\$PATH"

TMP_RC=\$(mktemp)
echo "source \"$out/etc/bashrc\"" > "\$TMP_RC"
echo "rm -f \"\$TMP_RC\"" >> "\$TMP_RC"

exec ${bash}/bin/bash --noprofile --rcfile "\$TMP_RC" -i
EOF
    chmod +x "$out/bin/openfoam-shell"
  '';
}
