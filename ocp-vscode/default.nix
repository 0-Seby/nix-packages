{
  buildPythonPackage,
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
    inherit pygltflib;
  };
in
buildPythonPackage rec {
  pname = "ocp-vscode";
  version = "3.4.0";
  src = fetchPypi {
    pname = "ocp_vscode";
    inherit version;
    hash = "sha256-jK4QuOCnoknrfymraKP7klU6uVj+Nn0t1zxrTJBgN1o="; # replace after first build attempt gives you the real hash
  };
  pyproject = true;
  build-system = [ setuptools ];
  dependencies = [
    ocp-tessellate
    threejs-materials
    pygltflib
  ] ++ (with pyPkgs; [
    requests ipykernel orjson websockets pyaml flask flask-sock click pyperclip questionary pillow
  ]);
  dontCheckRuntimeDeps = true;
  doCheck = true;
}
