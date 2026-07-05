
{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  webcolors,
  numpy,
  cachetools,
  imagesize
}:
buildPythonPackage rec {
  pname = "ocp-tessellate";
  version = "3.3.0";

  src = fetchFromGitHub {
    owner = "bernhard-42";
    repo = "ocp-tessellate";
    rev = "refs/tags/v${version}";
    hash = "sha256-m5WDPviy7Npl7Pb9A+qJHnX8FbZY4sCVOpIojoX3vbk=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  postPatch = ''
    sed -i 's/webcolors~=[0-9.]*/webcolors/g' pyproject.toml
    sed -i 's/cachetools~=[0-9.]*/cachetools/g' pyproject.toml
  '';

  dependencies = [
    webcolors
    numpy
    cachetools
    imagesize
  ];

  doCheck = true;
}
