{
  description = "Trame ecosystem";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pythonPackages = pkgs.python313Packages;
    in
    {
      packages.${system} = rec {
        # 1. Build local wslink
        wslink = pythonPackages.callPackage ./pkgs/wslink.nix {};

        trame-common = pythonPackages.callPackage ./pkgs/trame-common.nix { inherit wslink; };
        trame-client = pythonPackages.callPackage ./pkgs/trame-client.nix { inherit trame-common wslink; };
        trame-server = pythonPackages.callPackage ./pkgs/trame-server.nix { inherit trame-common wslink; };
        
        trame = pythonPackages.callPackage ./pkgs/trame.nix {
          inherit trame-server trame-client trame-common wslink;
        };
      };
    };
}
