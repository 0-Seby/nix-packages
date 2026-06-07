{
  # stdenv,
  cmake,
  ninja,
  python3,
  vtk,
  fetchFromGitHub,
  opencascade-occt,
  llvmPackages_21,
  libGL,
  libGLU,
  rapidjson,
  libxml2,
  freetype,
  libX11,
  gcc14Stdenv,
}:

let
  llvm = llvmPackages_21;

  pythonEnv = python3.withPackages (
    ps: with ps; [
      libclang
      pybind11
      joblib
      toml
      click
      jinja2
      logzero
      pandas
      path
      pyparsing
      schema
      tqdm
      toposort
      lief
    ]
  );

  stdenv = gcc14Stdenv; # pinning toolchain due to stricter error tolerance in newer versions ruining build

in
stdenv.mkDerivation rec {
  pname = "ocp-generate";
  version = "7.9.3.1";

  src = fetchFromGitHub {
    owner = "CadQuery";
    repo = "OCP";
    rev = version;
    hash = "sha256-TKvJ03WHVuUAMTHLr2KWjKU1rBoSOfpAIxjjpYKN2nQ=";
    fetchSubmodules = true;
  };

  patches = [ ./fix-libclang.patch ];

  postPatch = ''
    # Inject CMake list-unpacking loops right before the bindgen custom command block
    sed -i '/add_custom_command/i \
    foreach(inc IN LISTS OPENGL_INCLUDE_DIRS)\n    list(APPEND OPENGL_INCLUDES_FLAGS "-i" "''${inc}")\n    endforeach()\n    foreach(inc IN LISTS RapidJSON_INCLUDE_DIRS)\n    list(APPEND RAPIDJSON_INCLUDES_FLAGS "-i" "''${inc}")\n    endforeach()\n' CMakeLists.txt

    # Dynamically ask Clang exactly where its internal resource headers live in the Nix store
    CLANG_RES_DIR="$(${llvm.clang}/bin/clang -print-resource-dir)"

    # Swap the target arguments within the custom command to use the unpacked flags and the true Clang path
    substituteInPlace CMakeLists.txt \
      --replace-fail "-i \''${OPENGL_INCLUDE_DIRS}" "\''${OPENGL_INCLUDES_FLAGS}" \
      --replace-fail "-i \''${RapidJSON_INCLUDE_DIRS}" "\''${RAPIDJSON_INCLUDES_FLAGS}" \
      --replace-fail "\''${CLANG_INSTALL_PREFIX}/lib/clang/\''${LLVM_VERSION_MAJOR}/include/" "$CLANG_RES_DIR/include/"
  '';

  nativeBuildInputs = [
    cmake
    ninja
    pythonEnv
    llvm.llvm.dev
    llvm.clang-unwrapped.dev
    llvm.libclang.dev
  ];

  buildInputs = [
    opencascade-occt
    vtk
    libGL
    libGLU
    rapidjson
    libxml2 # Satisfies VTK
    freetype # Satisfies VTK
    libX11
  ];

  cmakeFlags = [
    "-DPLATFORM=Linux"
    "-DN_PROC=16"
    # Removed all the broken OpenMP hacks!
  ];

  buildPhase = ''
    cmake --build . --target pywrap -v
  '';

  installPhase = ''
    mkdir -p $out
    cp -r OCP/. $out/
    cp ${src}/OCP_specific.inc $out/
    cp ${src}/pystreambuf.h    $out/
    cp ${src}/vtk_pybind.h     $out/
  '';

  dontFixup = true;

  env = {
    LOKY_MAX_CPU_COUNT = "1";
    JOBLIB_TEMP_FOLDER = "/tmp";
  };
}
