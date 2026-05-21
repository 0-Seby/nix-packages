{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  tornado,
  six,
  hatchling,
  aiohttp,
  msgpack,
}:

buildPythonPackage rec {
  pname = "wslink";
  version = "2.5.7"; # Use the version that satisfies the requirement

  src = fetchFromGitHub {
    owner = "Kitware";
    repo = "wslink";
    rev = "v${version}";
    hash = "sha256-47vHc+b5Z3ipkLZ5k0yEasNaKz0Seu2jiGBVmAI5u6U="; # Run nix build to get the real hash
  };

  format = "pyproject";
  nativeBuildInputs = [
    setuptools
    wheel
    hatchling
    aiohttp
    msgpack
  ];
  propagatedBuildInputs = [
    tornado
    six
  ];
  doCheck = false;
}
