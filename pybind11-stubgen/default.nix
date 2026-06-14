{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pyparsing,
}:

buildPythonPackage rec {
  pname = "pybind11-stubgen";
  version = "unstable-2025-12-19";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "CadQuery";
    repo = "pybind11-stubgen";
    rev = "32e111a";
    hash = "sha256-QfznHc5eKFEbfNeZNbETuf5crLSs6yACweudjtwn0sY=";
  };

  build-system = [ setuptools ];

  doCheck = true;

  dependencies = [
    pyparsing
  ];

  meta = with lib; {
    description = "Modified pybind11-stubgen for OCP builds (CadQuery fork)";
    homepage = "https://github.com/CadQuery/pybind11-stubgen";
    license = licenses.bsd3;
  };
}
