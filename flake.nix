{
  description = "My Team's Custom Nix Packages";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      overlay = final: prev: {
        python3 = prev.python3.override {
          packageOverrides = pyFinal: pyPrev: {
            CoolProp = pyFinal.callPackage ./coolprop/default.nix { };
          };
        };
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          coolprop = pkgs.python3Packages.CoolProp;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              (pkgs.python3.withPackages (ps: [
                ps.CoolProp
                ps.numpy
                ps.rich
              ]))
            ];
          };
        }
      );
    };
}
