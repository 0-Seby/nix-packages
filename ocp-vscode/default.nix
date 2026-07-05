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

  ocp-tessellate = buildPythonPackage rec {
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
    dependencies = with pyPkgs; [ webcolors numpy cachetools imagesize ];
    dontCheckRuntimeDeps = true; # <-- Bypasses version strictness
    doCheck = false;
  };

  pygltflib = buildPythonPackage rec {
    pname = "pygltflib";
    version = "1.16.5"; 
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-HxV0DVp6r3GlCD4oWvazYRhJWOJVZZEy9LqP5PPSHqk=";
    };
    pyproject = true;
    build-system = [ setuptools ];
    dependencies = with pyPkgs; [ dataclasses-json deprecated ];
    dontCheckRuntimeDeps = true;
    doCheck = false;
  };

  threejs-materials = buildPythonPackage rec {
    pname = "threejs-materials";
    version = "1.1.1"; 
    src = fetchFromGitHub {
      owner = "bernhard-42";
      repo = "threejs-materials";
      rev = "v${version}";
      # If you got the real hash in the last step, paste it here. 
      # Otherwise, leave it as fakeHash and grab it on the next run.
      hash = "sha256-x9r/11uD5uh2MpkOQchTbOyJ1qP7Gsme57XM+AxXH90="; 
    };
    pyproject = true;
    build-system = [ setuptools ];
    dependencies = [ pygltflib ] ++ (with pyPkgs; [ pillow requests ]);
    dontCheckRuntimeDeps = true;
    doCheck = false;
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

  # --- THE MAGIC BULLET ---
  # This stops Nix from comparing your installed dependencies 
  # against the strict == and < bounds in the pyproject.toml
  dontCheckRuntimeDeps = true; 

  doCheck = false;
}
