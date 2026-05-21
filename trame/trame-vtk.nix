{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  trame-server,
  trame-client,
  trame-common,
  wslink,
  pyyaml,
  hatchling,
  pythonNamespacesHook,
}:

buildPythonPackage rec {
  pname = "trame-vtk";
  version = "2.11.8";

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "trame-vtk";
    rev = "v${version}";
    hash = "sha256-cNBHQS1nakRnFDbFLMwVEUzQj4zipY/z/5awuObMJJM=";
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
    trame-server
    trame-client
    trame-common
    wslink
    pyyaml
  ];

  pythonNamespaces = [
    "trame"
    "trame/tools"
    "trame/widgets"
    "trame/modules"
  ];

  doCheck = true;
}
