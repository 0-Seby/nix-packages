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
    # Instead of tags, use the specific commit hash
    rev = "b01e69cba3a3a2f1e78020b41718b78ac4b9047"; 
    hash = "sha256-MBhFeiZ6z630KdBkMS14ydWCA7uNY6e1wr+Va/tgw1E=";
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
  doCheck = true;
}