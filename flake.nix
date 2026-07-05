{
  description = "My Team's Custom Nix Packages";

  nixConfig = {
    extra-substituters = [ "https://seby.cachix.org" ];
    extra-trusted-public-keys = [ "seby.cachix.org-1:Vych8bxZ7KpUVrz2GELTegGr7th/kdAWHfzVVENyocc=" ];
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # == Python Overlay ==
      pythonPackagesOverlay =
        pyFinal: pyPrev:
        let
          customPkgs = {
            multicollections = pyFinal.callPackage ./multicollections/default.nix { };

            aioshutil = pyFinal.callPackage ./aioshutil/default.nix { };

            foamlib = pyFinal.callPackage ./foamlib/default.nix {
              multicollections = pyFinal.multicollections;
            };

            coolprop = pyFinal.callPackage ./coolprop/default.nix { };
            pyfluids = pyFinal.callPackage ./pyfluids/default.nix { };

            pybind11-2 = pyFinal.callPackage ./pybind11-2/default.nix { };
            pybind11-stubgen = pyFinal.callPackage ./pybind11-stubgen/default.nix { };

            ocp = pyFinal.callPackage ./ocp/default.nix {
              pybind11 = pyFinal.pybind11-2;
            };
            cadquery = pyFinal.callPackage ./cadquery/default.nix { };

            build123d = pyFinal.callPackage ./build123d/default.nix { };

            wslink = pyFinal.callPackage ./trame/wslink.nix { };

            trame-common = pyFinal.callPackage ./trame/trame-common.nix { };
            trame-server = pyFinal.callPackage ./trame/trame-server.nix { };
            trame-client = pyFinal.callPackage ./trame/trame-client.nix { };
            trame-vtk = pyFinal.callPackage ./trame/trame-vtk.nix { };
            trame-vuetify = pyFinal.callPackage ./trame/trame-vuetify.nix { };
            trame-components = pyFinal.callPackage ./trame/trame-components.nix { };
            trame = pyFinal.callPackage ./trame/trame.nix { };

            parsl = pyFinal.callPackage ./parsl/default.nix { };
          };
        in
        customPkgs
        // {
          customPackagesList = builtins.attrValues customPkgs;
          customPackageNames = builtins.attrNames customPkgs;
        };

      # == Main Overlay ==
      overlay = final: prev: {

        # === VTK <-> OpenCASCADE cycle break ==========================================
        # Genuine circular dependency:
        #   * VTK wants OCCT  -> IOOCCT (read STEP/IGES), needed for OCP to build.
        #   * OCCT wants VTK  -> IVtk  (render OCCT shapes), needed by cadquery/OCP viz.
        # Resolved by building OCCT twice (OCCT is the cheaper half):
        #   1. occt-bootstrap : OCCT with NO vtk          (breaks the knot)
        #   2. vtk            : VTK built against #1       (gains IOOCCT)
        #   3. opencascade-occt: OCCT built against #2     (gains IVtk; the "real" one)
        # Everything downstream (ocp, cadquery) uses #3 + #2. As a result OCP's closure
        # contains both OCCTs (full directly, bootstrap via VTK). This is expected.
        # DO NOT make vtk depend on opencascade-occt (#3) — that recreates the cycle.
        opencascade-occt-bootstrap = final.callPackage ./opencascade-occt/default.nix {
          vtk = null;
          useVtk = false;
        };

        vtk = prev.vtk.override {
          pythonSupport = true;
          opencascade-occt = final.opencascade-occt-bootstrap;
          python3Packages = final.python3.pkgs;
        };

        opencascade-occt = final.callPackage ./opencascade-occt/default.nix {
          vtk = final.vtk;
        };
        # ==============================================================================

        openfoam-core = final.callPackage ./openfoam/core.nix { };
        mkFoamPlugin = final.callPackage ./openfoam/mk-foam-plugin.nix { };
        foamPlugins = {
          bartz = final.callPackage ./openfoam-plugins/bartz/default.nix { };
        };
        openfoam = final.callPackage ./openfoam/default.nix { inherit (final) foamPlugins; };

        ocp-generate = final.callPackage ./ocp-generate/default.nix { };

        python3 = prev.python3.override {
          packageOverrides =
            pyFinal: pyPrev:
            (pythonPackagesOverlay pyFinal pyPrev)
            // {
              # final.vtk reads final.python3.pkgs, and this set re-injects vtk.
              # Safe only because vtk's python3Packages arg is never forced while
              # constructing this attr. toPythonModule binds pythonModule to THIS
              # set's interpreter so withPackages keeps vtkmodules on PYTHONPATH.
              # Keep it as `pyFinal.toPythonModule final.vtk` — don't rebuild vtk here.
              vtk = pyFinal.toPythonModule final.vtk;
            };
        };
      };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };

      pythonTestEnv =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.python3.withPackages (
          ps:
          ps.customPackagesList
          ++ [
            ps.numpy
            ps.rich
          ]
        );

    in
    {
      overlays = {
        default = overlay;
      };

      lib = {
        inherit pythonPackagesOverlay;

        # Bring your own pkgs + nixGL + isNixOS, get back a wrapper.
        # Usage in a consumer flake:
        #   withNixGL = sebPkgs.lib.withNixGL { inherit pkgs nixGL isNixOS; };
        #   pythonEnv = withNixGL { pkg = pyEnv; bins = [ "python" "jupyter" ]; };
        #   openfoam  = withNixGL { pkg = sebPkgs.openfoam; };  # uses passthru.guiBins
        withNixGL =
          {
            pkgs,
            nixGL,
            isNixOS,
          }:
          import ./lib/nixgl.nix {
            inherit pkgs nixGL isNixOS;
            lib = pkgs.lib;
          };
        pythonGuiBins = [
          "python"
          "python3"
          "python3.13"
          "jupyter"
          "jupyter-notebook"
          "ipython"
        ];
      };

      # == Exporter ==
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;

          myPackages = {
            inherit (pkgs)
              openfoam
              openfoam-core
              opencascade-occt
              ocp-generate
              vtk
              ;
            bartz = pkgs.foamPlugins.bartz;
          }
          // pkgs.lib.getAttrs pkgs.python3.pkgs.customPackageNames pkgs.python3.pkgs;

        in
        myPackages
        // {
          all = pkgs.linkFarm "all-my-packages" (
            pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) myPackages
          );
        }
      );

      legacyPackages = forAllSystems pkgsFor;

      # == Development Shell ==
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.openfoam
              (pkgs.python3.withPackages (
                ps:
                ps.customPackagesList
                ++ [
                  ps.numpy
                  ps.rich
                ]
              ))
            ];

            shellHook = ''
              # source the OpenFOAM initialization script
              if [ -f "${pkgs.openfoam}/bin/openfoam-init" ]; then
                source "${pkgs.openfoam}/bin/openfoam-init"
              else
                echo "Warning: Could not automatically locate OpenFOAM shell initialization script."
              fi
            '';
          };

          openfoam-bartz = pkgs.mkShell {
            packages = [ (pkgs.openfoam.withPackages (p: [ p.bartz ])) ];
            shellHook = ''
              source "${pkgs.openfoam.withPackages (p: [ p.bartz ])}/bin/openfoam-init"
            '';
          };
        }
      );

      # == Checking the python packages ==
      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          python = pythonTestEnv system;
        in
        {
          python-imports = pkgs.stdenv.mkDerivation {
            name = "python-import-checks";
            buildInputs = [ python ];
            dontUnpack = true;
            buildPhase = ''
              echo "Running Python import tests..."
              ${python}/bin/python ${./tests/imports.py}
            '';
            installPhase = ''
              mkdir -p $out
              touch $out/done
            '';
          };
        }
      );
    };
}
