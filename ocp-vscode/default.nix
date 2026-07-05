{
  buildPythonPackage,
  fetchFromGitHub,
  fetchPypi,
  setuptools,
  python,
  lib
}:
let
  pyPkgs = python.pkgs;

  ocp-tessellate = pyPkgs.callPackage ./ocp-tessellate.nix { };
  
  pygltflib = pyPkgs.callPackage ./pygltflib.nix { };
  
  threejs-materials = pyPkgs.callPackage ./threejs-materials.nix {
    inherit pygltflib; # Inject our custom pygltflib into this package
  };
in
buildPythonPackage rec {
  pname = "ocp-vscode";
  version = "3.4.0";

  src = fetchFromGitHub {
    owner = "bernhard-42";
    repo = "vscode-ocp-cad-viewer";
    rev = "refs/tags/v${version}";
    hash = "sha256-5xmpMEmrUMPgCw+WPujLU3lXx+PpzPKx7JYiMi2VAOs=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  dependencies = [
    ocp-tessellate 
    threejs-materials
    pygltflib
  ] ++ (with pyPkgs; [
    requests
    ipykernel
    orjson
    websockets
    pyaml
    flask
    flask-sock
    click
    pyperclip
    questionary
    pillow
  ]);

  dontCheckRuntimeDeps = true; 

  doCheck = false;
}
