{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  callPackage,
  isPy3k,
  pythonOlder,
  pytestCheckHook,
  pytest-xdist,
  pythonRelaxDepsHook,
  setuptools,
  setuptools-scm,
  ocp,
  typing-extensions,
  numpy,
  svgpathtools,
  svgelements,
  anytree,
  ezdxf,
  ipython,
  sympy,
  scipy,
  scikit-learn,
  webcolors,
  requests,
  autoPatchelfHook,
  stdenv,
  makeFontsConf,
  freefont_ttf,
}:
let
  ocpsvg = callPackage ./ocpsvg.nix { };
  ocp-gordon = callPackage ./ocp-gordon.nix { };
  trianglesolver = callPackage ./trianglesolver.nix { };
  lib3mf = callPackage ./lib3mf.nix { };
in
buildPythonPackage rec {
  pname = "build123d";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "gumyr";
    repo = "build123d";
    rev = "v${version}";
    hash = "sha256-UhdF4x01tGG0nVGCCwZA4mqfi9gVOSZ77a4RoKYmOFw=";
  };

  pyproject = true;
  build-system = [ setuptools setuptools-scm ];
  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  nativeBuildInputs = [
    setuptools-scm
    pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [
    "webcolors"
    "ipython"
    "scikit-learn"
    "numpy"
  ];

  propagatedBuildInputs = [
    ocp
    typing-extensions
    numpy
    svgpathtools
    anytree
    ezdxf
    ipython
    ocpsvg
    ocp-gordon
    trianglesolver
    sympy
    scipy
    scikit-learn
    webcolors
    requests
    lib3mf
  ];

  FONTCONFIG_FILE = makeFontsConf {
    fontDirectories = [ freefont_ttf ];
  };

  disabled = !isPy3k || pythonOlder "3.10";

  checkInputs = [
    pytestCheckHook
  ];

  preCheck = ''
    export HOME=$(mktemp -d)
    export XDG_CACHE_HOME=$(mktemp -d)
    sed -i '/^addopts/d' pyproject.toml
  '';

  pytestFlags = [
    "-p" "no:xdist"
    "-W" "ignore::FutureWarning"
    "-v"
    "tests"
  ];

  disabledTests = [
    "test_assembly_with_oriented_parts"
    "test_roundtrip_component_color_overrides_parent"
    "test_roundtrip_nested_labels_colors"
    "test_move_single_object"
    "test_single_label_color"
    "test_roundtrip_preserves_component_location"
    "test_single_object"
  ];

  pythonImportsCheck = [ "build123d" ];

  meta = with lib; {
    description = "A python CAD programming library";
    homepage = "https://github.com/gumyr/build123d";
    license = licenses.asl20;
    maintainers = [ ];
  };
}