{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
  ocp,
  numpy,
  scipy,
}:
buildPythonPackage rec {
  pname = "ocp_gordon";
  version = "0.2.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-POHx+1ieiRU00MH9dVOlGHMzNjCIN8S15RZNd98c9ck=";
  };

  pyproject = true;
  build-system = [ setuptools setuptools-scm ];
  propagatedBuildInputs = [ ocp numpy scipy ];
  doCheck = false;

  meta = with lib; {
    description = "Gordon Surface interpolation using B-splines for OCP";
    homepage = "https://github.com/gongfan99/ocp_gordon";
    license = licenses.asl20;
  };
}
