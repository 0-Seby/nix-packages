{ lib, buildPythonPackage, fetchPypi, setuptools, python }:

buildPythonPackage rec {
  pname = "pybind11";
  version = "2.13.6";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-umrxA0jBKyTpL6CGs5z7oO/2GbYax3xAYWfYE7CW05o=";  # build once, paste
  };

  build-system = [ setuptools ];

  # Expose the wheel-installed cmake/pkgconfig files where find_package looks.
  postInstall = ''
    mkdir -p $out/share
    ln -s $out/${python.sitePackages}/pybind11/share/cmake     $out/share/cmake
    ln -s $out/${python.sitePackages}/pybind11/share/pkgconfig $out/share/pkgconfig
    ln -s $out/${python.sitePackages}/pybind11/include         $out/include
  '';

  doCheck = false;

  meta = with lib; {
    description = "Seamless operability between C++11 and Python";
    homepage = "https://github.com/pybind/pybind11";
    license = licenses.bsd3;
  };
}
