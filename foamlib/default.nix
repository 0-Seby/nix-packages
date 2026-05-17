{ buildPythonPackage, fetchPypi, uv-build, numpy }:

buildPythonPackage rec {
  pname = "foamlib";
  version = "1.5.7";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-O2O6IP/ry7sPI66074Ah+qx1deX4V+ieB99+FRyInNw=";
  };

  nativeBuildInputs = [ uv-build ];
  
  propagatedBuildInputs = [ numpy ];
  
  doCheck = false;
}
