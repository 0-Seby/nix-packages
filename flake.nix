{
  description = "My Team's Custom Nix Packages";

  nixConfig = {
    extra-substituters = [ "https://seby.cachix.org" ];
    extra-trusted-public-keys = [ "seby.cachix.org-1:Vych8bxZ7KpUVrz2GELTegGr7th/kdAWHfzVVENyocc=" ];
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

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

            wslink = pyFinal.callPackage ./trame/wslink.nix { };

            trame-common = pyFinal.callPackage ./trame/trame-common.nix { };
            trame-server = pyFinal.callPackage ./trame/trame-server.nix { };
            trame-client = pyFinal.callPackage ./trame/trame-client.nix { };
            trame-vtk = pyFinal.callPackage ./trame/trame-vtk.nix { };
            trame-vuetify = pyFinal.callPackage ./trame/trame-vuetify.nix { };
            trame-components = pyFinal.callPackage ./trame/trame-components.nix { };
            trame = pyFinal.callPackage ./trame/trame.nix { };
          };
        in
        customPkgs
        // {
          customPackagesList = builtins.attrValues customPkgs;
          customPackageNames = builtins.attrNames customPkgs;
        };

      # == Main Overlay ==
      overlay = final: prev: {
        # Bootstrap VTK: stripped, only used to build OCCT. Breaks the cycle.
        vtk-for-occt =
          (prev.vtk.override {
            opencascade-occt = null;
            pythonSupport = false;
          }).overrideAttrs
            (old: {
              postPatch = (old.postPatch or "") + ''
                rm -rf IO/OCCT
              '';
            });

        # The real VTK everything else uses: OCCT support + Python wrapping.
        vtk = prev.vtk.override {
          pythonSupport = true;
        };

        opencascade-occt = final.callPackage ./opencascade-occt/default.nix {
          vtk = final.vtk-for-occt;
        };

        openfoam-13 = final.callPackage ./openfoam-13/default.nix { };
        ocp-generate = final.callPackage ./ocp-generate/default.nix { };

        python3 = prev.python3.override {
          packageOverrides = pyFinal: pyPrev: (pythonPackagesOverlay pyFinal pyPrev);
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
      };

      # == Exporter ==
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;

          # 1. Define your exported packages EXACTLY ONCE here.
          # Whenever you add a new package to your overlay, just add it to this list.
          myPackages = {
            inherit (pkgs) openfoam-13 opencascade-occt ocp-generate;
          } // pkgs.lib.getAttrs pkgs.python3.pkgs.customPackageNames pkgs.python3.pkgs;

        in
        # 2. Return all your packages, PLUS the dynamic 'all' collector.
        myPackages // {
          all = pkgs.linkFarm "all-my-packages" (
            pkgs.lib.mapAttrsToList (name: path: { inherit name path; }) myPackages
          );
        }
      );

      # == Development Shell ==
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.openfoam-13
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
              if [ -f "${pkgs.openfoam-13}/bin/openfoam-init" ]; then
                source "${pkgs.openfoam-13}/bin/openfoam-init"
              else
                echo "Warning: Could not automatically locate OpenFOAM shell initialization script."
              fi
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
