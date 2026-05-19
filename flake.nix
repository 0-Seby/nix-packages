{
  description = "My Team's Custom Nix Packages";

  nixConfig = {
    extra-substituters = [ "https://seby.cachix.org" ];
    extra-trusted-public-keys = [ "seby.cachix.org-1:Vych8bxZ7KpUVrz2GELTegGr7th/kdAWHfzVVENyocc=" ];
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      
      packages = forAllSystems (system:
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in rec {
          openfoam-13 = pkgs.callPackage ./openfoam-13/default.nix { };

          multicollections = pkgs.python3Packages.callPackage ./multicollections/default.nix { };
          
          foamlib = pkgs.python3Packages.callPackage ./foamlib/default.nix { 
            multicollections = multicollections; 
          };
        }
      );

      devShells = forAllSystems (system:
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.openfoam-13
              
              (pkgs.python3.withPackages (ps: [
                self.packages.${system}.foamlib
                ps.numpy
                ps.rich
              ]))
            ];
          };
        }
      );

    };
}
