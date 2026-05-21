{
  stdenv,
  lib,
  cmake,
  ninja,
  python,
  toPythonModule,
  opencascade-occt,
  vtk,
  pybind11,
  fmt,
  libGL,
  libGLU,
  xorg,
  rapidjson,
  ocp-generate,
}:
toPythonModule (
  stdenv.mkDerivation rec {
    pname = "ocp";
    version = "7.9.3.1";

    src = ocp-generate;

    nativeBuildInputs = [
      cmake
      ninja
      python
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      opencascade-occt
      vtk
      rapidjson # Restored!
      python
      pybind11
      fmt
      libGL
      libGLU
      xorg.libX11
      xorg.libXt
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DCMAKE_HAVE_LIBC_PTHREAD=ON"
      "-DCMAKE_THREAD_LIBS_INIT=-lpthread"
      # OpenMP detection bypasses — sandbox blocks try_compile probes.
      # GCC's libgomp provides OpenMP; these tell cmake not to probe for it.
      "-DOpenMP_CXX_FLAGS=-fopenmp"
      "-DOpenMP_CXX_LIB_NAMES=gomp"
      "-DOpenMP_gomp_LIBRARY=${stdenv.cc.cc.lib}/lib/libgomp.so"
      # ... rest of your existing flags
      "-DPYTHON_SP_DIR=${python.sitePackages}"
      "-DPython3_EXECUTABLE=${python}/bin/python3"
      "-DPython_EXECUTABLE=${python}/bin/python3"
      "-DPython3_ROOT_DIR=${python}"
      "-DPython_ROOT_DIR=${python}"
      "-DPython_FIND_STRATEGY=LOCATION"
      "-DPython3_FIND_STRATEGY=LOCATION"
      "-DCMAKE_CXX_FLAGS=-isystem ${rapidjson}/include"
    ];

    enableParallelBuilding = true;
    NIX_BUILD_CORES = "24";

    preConfigure = ''
      sed -i 's/find_package( VTK/find_package(OpenMP)\nfind_package( VTK/' CMakeLists.txt
    '';

    installPhase = ''
      mkdir -p $out/${python.sitePackages}
      cp OCP*.so $out/${python.sitePackages}/
    '';

    meta = with lib; {
      description = "Python bindings for OpenCASCADE Technology (OCCT)";
      homepage = "https://github.com/CadQuery/OCP";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  }
)
