{ pkgs ? import <nixpkgs> { } }:

let
  # 1. Override the Python interpreter
  python = pkgs.python313.override {
    packageOverrides = self: super: {
      wslink       = self.callPackage ./wslink.nix { };
      trame-common = self.callPackage ./trame-common.nix { };
      trame-client = self.callPackage ./trame-client.nix { };
      trame-server = self.callPackage ./trame-server.nix { };
      trame        = self.callPackage ./trame.nix { };
    };
  };

in
  python.pkgs
