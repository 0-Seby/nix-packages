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
    version = "2.4.1"; # Or the exact 2.3.x version you want
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

  nativeBuildInputs = [
    setuptools
    wheel
    uv-build
    coolprop
    tomli_2_3
  ];

  # This fixes your "not installed" error
  propagatedBuildInputs = [
    pythonNamespacesHook
    coolprop
    tomli_2_3
  ];

  # pythonNamespaces = [
  # ];

  doCheck = true;
}

