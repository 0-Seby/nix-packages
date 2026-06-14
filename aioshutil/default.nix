{
  buildPythonPackage,
  fetchPypi,
  setuptools-scm,
}:
buildPythonPackage rec {
  pname = "aioshutil";
  version = "1.6";
  pyproject = true;
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-nq40K5pMrMLCxYd4d6LS96K2bGKqGrV9fpXIz9Tt5Qc=";
  };
  build-system = [ setuptools-scm ];
  doCheck = true;
}
