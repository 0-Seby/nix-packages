{
  lib,
  buildPythonPackage,
  fetchPypi,
  autoPatchelfHook,
  stdenv,
}:
buildPythonPackage rec {
  pname = "lib3mf";
  version = "2.5.0";
  format = "wheel";

  src = fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    abi = "none";
    platform = "manylinux2014_x86_64";
    hash = "sha256-tMAAM8R8/qyTt9qgaftG6N6kOR1VIrec1un2r3XjMBM=";
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  doCheck = false;

  meta = with lib; {
    description = "Python bindings for lib3mf (3MF file format)";
    homepage = "https://github.com/3MFConsortium/lib3mf";
    license = licenses.bsd2;
    platforms = [ "x86_64-linux" ];
  };
}
