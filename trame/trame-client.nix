{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  trame-common,
  wslink,
  pyyaml,
  hatchling,
  pythonNamespacesHook,
}:

buildPythonPackage rec {
  pname = "trame-client";
  version = "3.12.2";

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "trame-client";
    rev = "v${version}";
    hash = "sha256-pLBeTb0Kf97VbWlfb6BJfJ43kE4t+rt/zgPtlflzT2Q=";
  };

  format = "pyproject";

  nativeBuildInputs = [
    setuptools
    wheel
    hatchling
    pythonNamespacesHook
  ];

  # This fixes your "not installed" error
  propagatedBuildInputs = [
    trame-common
    wslink
    pyyaml
  ];

  pythonNamespaces = [
    "trame"
    "trame/ui"
    "trame/modules"
  ];

  doCheck = true;
}
