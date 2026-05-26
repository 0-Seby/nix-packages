{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  pythonNamespacesHook,
  uv-build,
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
    rev = "${version}";
    hash = "sha256-CDXWx9/KKMr+rON7DbBI6amLwf/2T3ToHDxsL3XoVrU=";
  };

  format = "pyproject";

  nativeBuildInputs = [
    setuptools
    wheel
    uv-build
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

  propagatedBuildInputs = [
    pythonNamespacesHook
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

  # pythonNamespaces = [
  # ];

  doCheck = true;
}
