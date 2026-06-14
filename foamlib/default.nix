{
  buildPythonPackage,
  fetchPypi,
  uv-build,
  numpy,
  aioshutil,
  multicollections,
  rich,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "foamlib";
  version = "1.5.7";

  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-O2O6IP/ry7sPI66074Ah+qx1deX4V+ieB99+FRyInNw=";
  };

  build-system = [ uv-build ];

  dependencies = [
    numpy
    aioshutil
    multicollections
    rich
    typing-extensions
  ];

  doCheck = true;
}
