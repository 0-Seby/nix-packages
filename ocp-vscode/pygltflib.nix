{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  dataclasses-json,
  deprecated
}:
buildPythonPackage rec {
  pname = "pygltflib";
  version = "1.16.5"; 
  
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-HxV0DVp6r3GlCD4oWvazYRhJWOJVZZEy9LqP5PPSHqk=";
  };
  
  pyproject = true;
  build-system = [ setuptools ];
  
  dependencies = [ 
    dataclasses-json 
    deprecated 
  ];
  
  dontCheckRuntimeDeps = true;
  doCheck = false;
}