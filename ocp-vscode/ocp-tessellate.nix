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
  
  dependencies = [ 
    webcolors 
    numpy 
    cachetools 
    imagesize 
  ];
  
  dontCheckRuntimeDeps = true;
  doCheck = false;
}