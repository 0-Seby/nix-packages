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
  wmOptions = core.wmOptions;

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
    bash = "${bash}/bin/bash";
    sed = "${gnused}/bin/sed";
    coreutilsBin = "${coreutils}/bin";
    mpiPrefix = "${mpi}";
    inherit pvMajorMinor wmOptions runtimePath;
  };
in
stdenv.mkDerivation {
  pname = "openfoam";
  inherit (core) version;

  dontUnpack = true;
  dontBuild = true;

  buildInputs = [ core ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/etc

    mkdir -p $out/foam-bin
    for f in ${core}/bin/*; do
      ln -s "$f" "$out/foam-bin/$(basename "$f")"
    done

    for d in tutorials wmake src applications platforms site jobControl; do
      [ -e ${core}/$d ] && ln -s ${core}/$d $out/$d
    done

    for f in ${core}/etc/*; do
      ln -s "$f" "$out/etc/$(basename "$f")"
    done

    # 1. Capture the OpenFOAM environment.
    out=$out ${bash}/bin/bash ${
      replaceVars ./capture-env.sh (
        commonVars
        // {
          core = "${core}";
        }
      )
    }

    # 2. Translate to fish.
    out=$out ${bash}/bin/bash ${
      replaceVars ./generate-fish-env.sh {
        sed = "${gnused}/bin/sed";
      }
    }

    # 3. Install entrypoints — substitute @out@ here so it resolves to
    #    THIS derivation's $out, not the template file's store path.
    cp ${./openfoam-init.in}      $out/bin/openfoam-init
    cp ${./openfoam-init.fish.in} $out/bin/openfoam-init.fish

    substitute ${./openfoam-shell.in} $out/bin/openfoam-shell \
      --subst-var-by bash ${bash}/bin/bash
    chmod +x $out/bin/openfoam-shell

    runHook postInstall
  '';

  passthru = {
    inherit core;
    guiBins = [
      "paraview"
      "paraFoam"
      "paraFoamServer"
      "foamCreateVideo"
      "pdfPlot"
      "foamMonitor"
    ];
    guiBinsDir = "foam-bin";
  };

  meta = core.meta or { };
}
