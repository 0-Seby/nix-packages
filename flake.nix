{
  description = "Custom Packages";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        openfoam-13 = pkgs.callPackage ./openfoam-13/default.nix { };
        default = self.packages.${system}.openfoam-13;
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          self.packages.${system}.openfoam-13
        ];
      };
    };
}
