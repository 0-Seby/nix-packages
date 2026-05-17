{
  description = "My Team's Custom Nix Packages";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      
      packages = forAllSystems (system:
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          openfoam-13 = pkgs.callPackage ./openfoam-13/default.nix { };
          foamlib = pkgs.python3Packages.callPackage ./foamlib/default.nix { };
          default = self.packages.${system}.openfoam-13;
        }
      );

      devShells = forAllSystems (system:
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = [
              self.packages.${system}.openfoam-13
            ];
          };
        }
      );

    };
}
