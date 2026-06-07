# adapted from github:conda-forge/occt-feedstock which is the canonical cadquery source.
{
  stdenv,
  lib,
  fetchurl,
  fetchpatch,
  cmake,
  ninja,
  tcl,
  tk,
  vtk,
  useVtk ? true,
  libGL,
  libGLU,
  libXext,
  libXmu,
  libXi,
  libXt,
  freetype,
  fontconfig,
  rapidjson,
  glew,
  tbb,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "opencascade-occt";
  version = "7.9.3";
  tag = "V${builtins.replaceStrings [ "." ] [ "_" ] version}";

  src = fetchFromGitHub {
    owner = "Open-Cascade-SAS";
    repo = "OCCT";
    rev = tag;
    hash = "sha256-Zp4m+f1wrzynoCrzIwvYELUXsY/NQIBY+HFk5UteufI=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];
  buildInputs = [
    vtk
    tcl
    tk
    libGL
    libGLU
    libXext
    libXmu
    libXi
    libXt
    freetype
    fontconfig
    tbb
    rapidjson
    glew
  ]
  ++ lib.optional useVtk vtk;

  cmakeFlags = [
    "-D BUILD_MODULE_Draw:BOOL=OFF"
    "-D USE_TBB:BOOL=ON"
    "-D BUILD_RELEASE_DISABLE_EXCEPTIONS=OFF"
    "-D USE_FREEIMAGE:BOOL=OFF"
    "-D USE_RAPIDJSON:BOOL=ON"
  ]
  ++ lib.optionals useVtk [
    "-D USE_VTK:BOOL=ON"
    "-D3RDPARTY_VTK_DIR=${vtk}"
  ];

  separateDebugInfo = true;

  meta = with lib; {
    description = "Open CASCADE Technology, libraries for 3D modeling and numerical simulation";
    homepage = "https://www.opencascade.org/";
    license = licenses.lgpl21;
    # The special exception defined in the file OCCT_LGPL_EXCEPTION.txt
    # are basically about making the license a little less share-alike.
    maintainers = with maintainers; [ marcus7070 ];
    platforms = platforms.all;
  };

}
