{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pyzmq,
  typeguard,
  typing-extensions,
  dill,
  tblib,
  requests,
  sortedcontainers,
  psutil,
  setproctitle,
  filelock,
}:
buildPythonPackage rec {
  pname = "parsl";
  version = "2026.05.25";

  src = fetchFromGitHub {
    owner = "Parsl";
    repo = "parsl";
    rev = "refs/tags/${version}";
    hash = "sha256-CDXWx9/KKMr+rON7DbBI6amLwf/2T3ToHDxsL3XoVrU=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  dependencies = [
    pyzmq
    typeguard
    typing-extensions
    dill
    tblib
    requests
    sortedcontainers
    psutil
    setproctitle
    filelock
  ];

  doCheck = true;
}
