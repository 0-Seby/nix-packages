{ buildPythonPackage, fetchPypi, uv-build }: # <--- Swapped to hatchling

buildPythonPackage rec {
  pname = "multicollections";
  version = "1.0.8"; 

  format = "pyproject"; 

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-qut7LB9KVKUIhnk1BoVpIppn+b4z+pPbwYIiHie2l2o="; 
  };

  # Swap the build backend here too
  nativeBuildInputs = [ uv-build ];

  doCheck = false; 
}
