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
  pythonNamespacesHook,
}:

buildPythonPackage rec {
  pname = "trame";
  version = "3.13.2";

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "trame";
    rev = "v${version}";
    hash = "sha256-g3A12JavsmCVleadIphrj6XtokEE0qnZTHiJ0XVCXmc=";
  };

  pyproject = true;

  build-system = [
    setuptools
    wheel
    pythonNamespacesHook
  ];

  dependencies = [
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
    "trame/tools"
  ];

  doCheck = false;
}
