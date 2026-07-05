{
  lib,
  buildPythonPackage,
  fetchPypi,
}:
buildPythonPackage rec {
  pname = "trianglesolver";
  version = "1.2";
  format = "wheel";

  src = fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    abi = "none";
    platform = "any";
    hash = "sha256-qgkDw3CLTitJbwbUkMrnLG/2J0sA0e3OQg/Po7K3ZoI=";
  };

  doCheck = true;

  meta = with lib; {
    description = "Solves triangles given some sides and angles";
    homepage = "https://github.com/sbyrnes321/trianglesolver";
    license = licenses.mit;
  };
}
