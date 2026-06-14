{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  pythonNamespacesHook,
  uv-build,
  coolprop,
  tomli,
}:
let
  tomli_2_3 = tomli.overridePythonAttrs (oldAttrs: rec {
    version = "2.4.1";
    src = fetchFromGitHub {
      owner = "hukkin";
      repo = "tomli";
      rev = version;
      hash = "sha256-MBcmp0SeK/wum3c2c/eu8VEofXDguolHI30QwKahAGE=";
    };
  });
in
buildPythonPackage rec {
  pname = "pyfluids";
  version = "2.9.0";

  src = fetchFromGitHub {
    owner = "portyanikhin";
    repo = "PyFluids";
    rev = "v${version}";
    hash = "sha256-Dkqnv9uzlC+hi2CtoHpfaIQezhbounqfFCAH9/+6UuM=";
  };

  format = "pyproject";

  build-system = [
    setuptools
    wheel
    uv-build
  ];

  dependencies = [
    pythonNamespacesHook
    coolprop
    tomli_2_3
  ];

  doCheck = true;
}

