{ buildPythonPackage, fetchPypi, uv-build }:

buildPythonPackage rec {
  pname = "multicollections";
  version = "1.0.8"; 

  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-qut7LB9KVKUIhnk1BoVpIppn+b4z+pPbwYIiHie2l2o="; 
  };

  nativeBuildInputs = [ uv-build ];

  doCheck = false; 
}
