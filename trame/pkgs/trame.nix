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

  format = "pyproject";

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  # This fixes your "not installed" error
  propagatedBuildInputs = [
    trame-server
    trame-client
    trame-common
    wslink
    pyyaml
  ];

  doCheck = false;
}
