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
  pname = "trame-components";
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "trame-components";
    rev = "v${version}";
    hash = "sha256-Qn3HMVEXPp0H7nqtIbHopT10ZYXf/zB0y++gX+MykOo=";
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
    "trame/widgets"
    "trame/modules"
  ];

  doCheck = true;
}
