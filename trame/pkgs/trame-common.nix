{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  wslink,
  pyyaml,
  hatchling,
}:

buildPythonPackage rec {
  pname = "trame-common";
  version = "1.2.3";

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "trame-common";
    rev = "v${version}";
    hash = "sha256-sqyEiMeuG0vA0ZaHmQiedAXx3HT/bfiN/JIOeNq+N2Q=";
  };

  format = "pyproject";

  nativeBuildInputs = [
    setuptools
    wheel
    hatchling
  ];

  # This fixes your "not installed" error
  propagatedBuildInputs = [
    wslink
    pyyaml
  ];

  doCheck = false;
}
