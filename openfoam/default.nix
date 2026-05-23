{
  lib,
  stdenv,
  callPackage,
  replaceVars,
  bash,
  coreutils,
  findutils,
  gawk,
  gnumake,
  gnused,
  mpi,
  paraview,
  gnuplot,
  openfoam-core,
  ...
}@args:

let
  core = openfoam-core;

  pvMajorMinor = core.pvMajorMinor;
  wmOptions    = core.wmOptions;

  runtimePath = lib.makeBinPath [
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
  ];

  commonVars = {
    bash         = "${bash}/bin/bash";
    sed          = "${gnused}/bin/sed";
    coreutilsBin = "${coreutils}/bin";
    mpiPrefix    = "${mpi}";
    inherit pvMajorMinor wmOptions runtimePath;
  };
in
stdenv.mkDerivation {
  pname = "openfoam";
  inherit (core) version;

  dontUnpack = true;
  dontBuild  = true;

  buildInputs = [ core ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/etc

    # Pass-through the heavy directories as symlinks.
    for d in tutorials wmake src applications platforms site jobControl; do
      [ -e ${core}/$d ] && ln -s ${core}/$d $out/$d
    done

    # Symlink individual entries from core's bin/ and etc/ so we can
    # add our own files alongside them.
    for f in ${core}/bin/*; do
      ln -s "$f" "$out/bin/$(basename "$f")"
    done
    for f in ${core}/etc/*; do
      ln -s "$f" "$out/etc/$(basename "$f")"
    done

    # 1. Capture the OpenFOAM environment to a fast-replayable file.
    out=$out ${bash}/bin/bash ${replaceVars ./capture-env.sh (commonVars // {
      core = "${core}";
    })}

    # 2. Translate the bash env file into fish syntax.
    out=$out ${bash}/bin/bash ${replaceVars ./generate-fish-env.sh {
      sed = "${gnused}/bin/sed";
    }}

    # 3. Install the user-facing entrypoints.
    install -m755 ${replaceVars ./openfoam-init.in {
      out = placeholder "out";
    }} $out/bin/openfoam-init

    install -m755 ${replaceVars ./openfoam-init.fish.in {
      out = placeholder "out";
    }} $out/bin/openfoam-init.fish

    install -m755 ${replaceVars ./openfoam-shell.in {
      out  = placeholder "out";
      bash = "${bash}/bin/bash";
    }} $out/bin/openfoam-shell

    runHook postInstall
  '';

  passthru = { inherit core; };

  meta = core.meta or {};
}
