{
  lib,
  stdenv,
  callPackage,
  replaceVars,
  writeText,
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
  foamPlugins ? { },
  ...
}@args:

let
  core = openfoam-core;

  pvMajorMinor = core.pvMajorMinor;
  wmOptions = core.wmOptions;

  runtimePath = lib.makeBinPath [
    (lib.getDev mpi) mpi paraview gnuplot
    coreutils findutils gawk gnused gnumake stdenv.cc
  ];

  commonVars = {
    bash = "${bash}/bin/bash";
    sed = "${gnused}/bin/sed";
    coreutilsBin = "${coreutils}/bin";
    mpiPrefix = "${mpi}";
    inherit pvMajorMinor wmOptions runtimePath;
  };

  wrap = base: plugins:
    let
      extraBash = lib.optionalString (plugins != [ ]) ''

        # --- added by withPackages ---
        export LD_LIBRARY_PATH="${lib.makeLibraryPath plugins}''${LD_LIBRARY_PATH:+:''${LD_LIBRARY_PATH}}"
        export PATH="${lib.makeBinPath plugins}''${PATH:+:''${PATH}}"
      '';
      extraFish = lib.optionalString (plugins != [ ]) ''

        # --- added by withPackages ---
        set -gx LD_LIBRARY_PATH ${lib.concatMapStringsSep " " (p: "${p}/lib") plugins} $LD_LIBRARY_PATH
        set -gx PATH ${lib.concatMapStringsSep " " (p: "${p}/bin") plugins} $PATH
      '';
      fragBash = writeText "of-plugin-env.sh" extraBash;
      fragFish = writeText "of-plugin-env.fish" extraFish;
    in
    stdenv.mkDerivation {
      pname = "${base.pname}-with-packages";
      inherit (base) version;
      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin

        # Mirror base's top-level layout (self-contained dir-symlinks).
        for d in etc tutorials wmake src applications platforms site jobControl; do
          [ -e ${base}/$d ] && ln -s ${base}/$d $out/$d
        done

        # foam-bin must be a DIRECTORY OF INDIVIDUAL SYMLINKS (not one
        # dir-symlink) so a later nixGL symlinkJoin can rm/replace leaves.
        mkdir -p $out/foam-bin
        for f in ${base}/foam-bin/*; do
          ln -s "$f" "$out/foam-bin/$(basename "$f")"
        done

        # Symlink all of base's bin EXCEPT the inits, which we regenerate.
        for f in ${base}/bin/*; do
          name=$(basename "$f")
          case "$name" in openfoam-init|openfoam-init.fish) continue ;; esac
          ln -s "$f" "$out/bin/$name"
        done

        substitute ${./openfoam-init.in} $out/bin/openfoam-init \
          --subst-var-by envCache "${base}/etc/openfoam-env.sh"
        cat ${fragBash} >> $out/bin/openfoam-init

        substitute ${./openfoam-init.fish.in} $out/bin/openfoam-init.fish \
          --subst-var-by envCache "${base}/etc/openfoam-env.fish"
        cat ${fragFish} >> $out/bin/openfoam-init.fish

        runHook postInstall
      '';

      passthru = {
        inherit (base.passthru) core guiBins guiBinsDir;
        plugins = plugins;
      };
      meta = base.meta or { };
    };

  self = stdenv.mkDerivation {
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

      out=$out ${bash}/bin/bash ${
        replaceVars ./capture-env.sh (commonVars // { core = "${core}"; })
      }

      out=$out ${bash}/bin/bash ${
        replaceVars ./generate-fish-env.sh { sed = "${gnused}/bin/sed"; }
      }

      substitute ${./openfoam-init.in}      $out/bin/openfoam-init \
        --subst-var-by envCache "$out/etc/openfoam-env.sh"
      substitute ${./openfoam-init.fish.in} $out/bin/openfoam-init.fish \
        --subst-var-by envCache "$out/etc/openfoam-env.fish"

      substitute ${./openfoam-shell.in} $out/bin/openfoam-shell \
        --subst-var-by bash ${bash}/bin/bash
      chmod +x $out/bin/openfoam-shell

      runHook postInstall
    '';

    passthru = {
      inherit core;
      guiBins = [
        "paraview" "paraFoam" "paraFoamServer"
        "foamCreateVideo" "pdfPlot" "foamMonitor"
      ];
      guiBinsDir = "foam-bin";
      withPackages = selector: wrap self (selector foamPlugins);
    };

    meta = core.meta or { };
  };
in
self
