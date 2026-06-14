{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  trame-common,
  wslink,
  pyyaml,
  hatchling,
  more-itertools,
  pythonNamespacesHook,
}:

buildPythonPackage rec {
  pname = "trame-server";
  version = "3.12.4";

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "trame-server";
    rev = "v${version}";
    hash = "sha256-gJD3HwBVUtPyMwotU6IT8nwQVPDO3tSVgJ9R8TRomZQ=";
  };

  pyproject = true;

  build-system = [
    setuptools
    wheel
    hatchling
    more-itertools
    pythonNamespacesHook
  ];

  dependencies = [
    trame-common
    wslink
    pyyaml
  ];

  pythonNamespaces = [
    "trame"
  ];

  doCheck = false;
}
