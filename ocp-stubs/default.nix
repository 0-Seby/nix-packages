{ lib, stdenv, buildPythonPackage, fetchPypi }:

let
  platformTag = {
    "x86_64-linux"  = "manylinux_2_31_x86_64";
    "aarch64-linux" = "manylinux_2_31_aarch64";
    "x86_64-darwin" = "macosx_11_0_x86_64";
    "aarch64-darwin" = "macosx_11_0_arm64";
  }.${stdenv.hostPlatform.system}
    or (throw "cadquery-ocp-stubs: unsupported system ${stdenv.hostPlatform.system}");
in
buildPythonPackage rec {
  pname = "cadquery-ocp-stubs";
  version = "7.9.3.1";
  format = "wheel";

  src = fetchPypi {
    pname    = "cadquery_ocp_stubs";
    inherit version format;
    python   = "py3";
    dist     = "py3";
    abi      = "none";
    platform = platformTag;
    hash     = "sha256-hB65hToKlDSKc4DuvjI5s+BBuVa2HbQk6C3zuUGHDdQ=";   # build once per platform you care about, paste hash
  };

  doCheck = false;

  meta = with lib; {
    description = "Typing stubs for cadquery-ocp";
    homepage = "https://pypi.org/project/cadquery-ocp-stubs/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
