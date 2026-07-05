{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
  ocp,
  svgelements,
}:
buildPythonPackage rec {
  pname = "ocpsvg";
  version = "0.6.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-8I2kNHzJDs01ZTlem9pXRtRquKr9aiaBuwOpwyG1QDk=";
  };

  pyproject = true;
  build-system = [ setuptools setuptools-scm ];
  propagatedBuildInputs = [ ocp svgelements ];
  doCheck = false;

  meta = with lib; {
    description = "SVG import/export at the OCP level";
    homepage = "https://github.com/snoyer/ocpsvg";
    license = licenses.mit;
  };
}
