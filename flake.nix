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

      # Python Overlay
      pythonPackagesOverlay = pyFinal: pyPrev: {
        multicollections = pyFinal.callPackage ./multicollections/default.nix { };

        foamlib = pyFinal.callPackage ./foamlib/default.nix {
          multicollections = pyFinal.multicollections;
        };

        coolprop = pyFinal.callPackage ./coolprop/default.nix { };

        ocp = pyFinal.callPackage ./ocp/default.nix { };
      };

      # Main Overlay
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
          # opencascade-occt input is picked up automatically from final scope
          # (which is your custom OCCT, built against vtk-for-occt above)
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
        pkgs.python3.withPackages (ps: [
          ps.numpy
          ps.rich
          ps.foamlib
          ps.multicollections
          ps.coolprop
          ps.ocp
        ]);

    in
    {
      overlays = {
        default = overlay;
      };

      lib = {
        inherit pythonPackagesOverlay;
      };

      # Exporter
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          # Top-level packages
          inherit (pkgs) openfoam-13 opencascade-occt ocp-generate;

          # Python packages
          inherit (pkgs.python3.pkgs)
            multicollections
            foamlib
            coolprop
            ocp
            ;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.openfoam-13
              (pkgs.python3.withPackages (ps: [
                ps.multicollections
                ps.foamlib
                ps.coolprop
                ps.numpy
                ps.rich
                ps.ocp
              ]))
            ];
          };
        }
      );

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
