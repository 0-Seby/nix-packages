{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pyparsing,
}:

buildPythonPackage rec {
  pname = "pybind11-stubgen";
  version = "unstable-2025-12-19"; # match last commit date you pin

  pyproject = true;

  src = fetchFromGitHub {
    owner = "CadQuery";
    repo = "pybind11-stubgen";
    rev = "32e111a"; # <-- replace with the commit hash from CadQuery/pybind11-stubgen
    hash = "sha256-QfznHc5eKFEbfNeZNbETuf5crLSs6yACweudjtwn0sY="; # build once with empty hash, paste the `got:` value
  };

  build-system = [ setuptools ];

  # The fork's tests assume some dev fixtures we don't need to ship.
  doCheck = true;

  nativeBuildInputs = [
    pyparsing
  ];

  meta = with lib; {
    description = "Modified pybind11-stubgen for OCP builds (CadQuery fork)";
    homepage = "https://github.com/CadQuery/pybind11-stubgen";
    license = licenses.bsd3;
  };
}
