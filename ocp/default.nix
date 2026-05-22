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
  pybind11-stubgen, # <-- new
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
      pybind11-stubgen
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      opencascade-occt
      vtk
      rapidjson
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
      "-DOpenMP_CXX_FLAGS=-fopenmp"
      "-DOpenMP_CXX_LIB_NAMES=gomp"
      "-DOpenMP_gomp_LIBRARY=${stdenv.cc.cc.lib}/lib/libgomp.so"
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

    preConfigure = ''
      sed -i 's/find_package( VTK/find_package(OpenMP)\nfind_package( VTK/' CMakeLists.txt
    '';

    installPhase = ''
      mkdir -p $out/${python.sitePackages}
      cp OCP*.so $out/${python.sitePackages}/

      export PYTHONPATH=$out/${python.sitePackages}:$PYTHONPATH
      export HOME=$(mktemp -d)

      echo "Generating OCP type stubs (this takes a few minutes)..."
      pybind11-stubgen \
        -o $out/${python.sitePackages} \
        --no-setup-py \
        OCP \
        || echo "pybind11-stubgen completed with warnings"

      TOP_INIT="$out/${python.sitePackages}/OCP-stubs/__init__.pyi"
      for d in "$out/${python.sitePackages}/OCP-stubs"/*/; do
        sub=$(basename "$d")
        grep -qF "from . import $sub as $sub" "$TOP_INIT" \
          || echo "from . import $sub as $sub" >> "$TOP_INIT"
      done

      # Verify the run was actually complete, not aborted after one submodule.
      STUB_COUNT=$(find $out/${python.sitePackages}/OCP-stubs -name '__init__.pyi' 2>/dev/null | wc -l)
      echo "Generated $STUB_COUNT stub modules."
      if [ "$STUB_COUNT" -lt 100 ]; then
        echo "ERROR: stub generation appears to have crashed mid-run."
        echo "Expected hundreds of submodules; got $STUB_COUNT."
        exit 1
      fi
      touch $out/${python.sitePackages}/OCP-stubs/py.typed

      # Existing dist-info metadata
      DIST_INFO="$out/${python.sitePackages}/cadquery_ocp-${version}.dist-info"
      mkdir -p "$DIST_INFO"
      cat > "$DIST_INFO/METADATA" <<EOF
      Metadata-Version: 2.1
      Name: cadquery-ocp
      Version: ${version}
      Summary: Python bindings for OpenCASCADE Technology (OCCT)
      EOF
    '';

    env = {
      NIX_LDFLAGS = "-lfmt";
    };

    meta = with lib; {
      description = "Python bindings for OpenCASCADE Technology (OCCT)";
      homepage = "https://github.com/CadQuery/OCP";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
    };
  }
)
