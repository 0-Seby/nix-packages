{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  cython,
  scikit-build-core,
  cmake,
  ninja,
  numpy,
}:

buildPythonPackage rec {
  pname = "CoolProp";
  version = "7.2.0";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "CoolProp";
    repo = "CoolProp";
    rev = "v${version}";
    hash = "sha256-/x6kKg1nCqGOOuR/vaeMEdf9AyqBWLKn5YgMG9shhAw=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cython
    scikit-build-core
    cmake
    ninja
  ];

  propagatedBuildInputs = [
    numpy
  ];

  # important: prevent Nix cmake hooks from messing with the cwd
  dontUseCmakeConfigure = true;
  dontUseCmakeBuild = true;
  dontUseCmakeInstall = true;

  preBuild = ''
    echo "PWD before buildPhase: $PWD"
    ls -la
  '';

  pythonImportsCheck = [ "CoolProp" ];

  meta = with lib; {
    description = "Thermophysical properties for the masses";
    homepage = "http://www.coolprop.org";
    license = licenses.mit;
  };
}
