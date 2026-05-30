{
  lib,
  stdenv,
  patchelf,
  openfoam-core,
  mpi,
}:

{
  pname,
  version ? "0-unstable",
  src,
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
}:

let
  wmOptions = openfoam-core.wmOptions;
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ patchelf ] ++ nativeBuildInputs;
  buildInputs = [ openfoam-core mpi ] ++ buildInputs;

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR"
    mkdir -p "$HOME"

    # Pull in the full OpenFOAM build environment from core.
    export WM_PROJECT_DIR=${openfoam-core}
    source ${openfoam-core}/etc/bashrc

    export WM_NCOMPPROCS="$NIX_BUILD_CORES"

    # Send wmake's "user library" output into this derivation instead of $HOME.
    export FOAM_USER_LIBBIN="$out/lib"
    export FOAM_USER_APPBIN="$out/bin"
    mkdir -p "$FOAM_USER_LIBBIN" "$FOAM_USER_APPBIN"

    # Drop anything left over from a previous (non-Nix) build, refresh lnInclude.
    wclean 2>/dev/null || true
    wmakeLnInclude -u .
    wmake libso

    runHook postBuild
  '';

  dontInstall = true;

  postFixup = ''
    for so in "$out"/lib/*.so; do
      [ -e "$so" ] || continue
      patchelf --add-rpath "${openfoam-core}/platforms/${wmOptions}/lib" "$so" || true
      patchelf --add-rpath "${mpi}/lib" "$so" || true
    done
  '';
}
