{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools-scm,
  isPy3k,
  pythonOlder,
  fetchFromGitHub,
  makeFontsConf,
  freefont_ttf,
  pytestCheckHook,
  pytest-xdist,
  ocp,
  casadi,
  ezdxf,
  ipython,
  nptyping,
  vtk,
  nlopt,
  multimethod,
  docutils,
  path,
  setuptools,
  poetry-core,
  pythonRelaxDepsHook,
  scipy,
  numba,
  trame,
  trame-vtk,
  trame-components,
  trame-vuetify,
  aiohttp,
  msgpack,
  more-itertools,
}:

let
  runtype = buildPythonPackage rec {
    pname = "runtype";
    version = "0.5.3";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-zK7AXHT40hM0K5/CXjBFYNEUvE1y7BF2Oc0eevnF2x8="; # Ensure this is your working runtype hash
    };

    pyproject = true;
    build-system = [ poetry-core ];
    doCheck = false;
  };
in
buildPythonPackage rec {
  pname = "cadquery";
  version = "unstable-2026-05-17"; # Date of the latest commit

  src = fetchFromGitHub {
    owner = "CadQuery";
    repo = "cadquery";
    rev = "8c17892";
    hash = "sha256-+FoXWscnsY/x5yQGnRDTl6CDWH+Q/y9MFOctVncCH9E=";
    fetchSubmodules = true;
  };

  pyproject = true;
  build-system = [ setuptools ];

  SETUPTOOLS_SCM_PRETEND_VERSION = "2.8.0.dev0"; # Matches what their setup.py expects

  nativeBuildInputs = [
    setuptools-scm
    pythonRelaxDepsHook
  ];

  # No patchPhase needed anymore! Upstream master natively supports OCP 7.9.3.1

  pythonRemoveDeps = [
    "casadi"
  ];

  pythonRelaxDeps = [
    "multimethod"
  ];

  propagatedBuildInputs = [
    ocp
    ezdxf
    casadi
    ipython
    nptyping
    runtype
    vtk
    nlopt
    multimethod
    scipy
    numba
    trame
    trame-vtk
    trame-components
    trame-vuetify
    aiohttp
    msgpack
    more-itertools
  ];

  FONTCONFIG_FILE = makeFontsConf {
    fontDirectories = [ freefont_ttf ];
  };

  disabled = !isPy3k;

  checkInputs = [
    pytestCheckHook
    pytest-xdist
    docutils
    path
  ];

  preCheck = ''
    export HOME=$(mktemp -d)
    export XDG_CACHE_HOME=$(mktemp -d)
  '';

  pytestFlags = [
    "-W"
    "ignore::FutureWarning"
    "-v" # Verbose: this will print every test it finds to the log
    "tests" # Explicitly point to the tests folder
  ];

  meta = with lib; {
    description = "Parametric scripting language for creating and traversing CAD models";
    homepage = "https://github.com/CadQuery/cadquery";
    license = licenses.asl20;
    maintainers = with maintainers; [
      costrouc
      marcus7070
    ];
  };
}
