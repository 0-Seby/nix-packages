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
  pname = "trame-vuetify";
  version = "3.2.2";

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "trame-vuetify";
    rev = "v${version}";
    hash = "sha256-kanJCwy4mYl16+RG1rucAzJvbbbxV7lpVHAJHlfQaAs=";
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
    "trame/ui"
    "trame/widgets"
    "trame/modules"
  ];

  doCheck = true;
}
