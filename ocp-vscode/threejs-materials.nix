{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pygltflib,
  pillow,
  requests
}:
buildPythonPackage rec {
  pname = "threejs-materials";
  version = "1.1.1"; 
  
  src = fetchFromGitHub {
    owner = "bernhard-42";
    repo = "threejs-materials";
    rev = "v${version}";
    hash = "sha256-x9r/11uD5uh2MpkOQchTbOyJ1qP7Gsme57XM+AxXH90="; 
  };
  
  pyproject = true;
  build-system = [ setuptools ];
  
  dependencies = [ 
    pygltflib 
    pillow 
    requests 
  ];
  
  dontCheckRuntimeDeps = true;
  doCheck = false;
}
