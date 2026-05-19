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

      pythonPackagesOverlay = pyFinal: pyPrev: {
        multicollections = pyFinal.callPackage ./multicollections/default.nix { };

        foamlib = pyFinal.callPackage ./foamlib/default.nix {
          multicollections = pyFinal.multicollections;
        };

        CoolProp = pyFinal.callPackage ./coolprop/default.nix { };
      };

      overlay = final: prev: {
        python3 = prev.python3.override {
          packageOverrides = pythonPackagesOverlay;
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
          ps.CoolProp
        ]);
    in
    {
      overlays = {
        default = overlay;
      };

      lib = {
        pythonPackagesOverlay = pythonPackagesOverlay;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          openfoam-13 = pkgs.callPackage ./openfoam-13/default.nix { };
          multicollections = pkgs.python3.pkgs.multicollections;
          foamlib = pkgs.python3.pkgs.foamlib;
          coolprop = pkgs.python3.pkgs.CoolProp;
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
              self.packages.${system}.openfoam-13
              (pkgs.python3.withPackages (ps: [
                ps.multicollections
                ps.foamlib
                ps.CoolProp
                ps.numpy
                ps.rich
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
