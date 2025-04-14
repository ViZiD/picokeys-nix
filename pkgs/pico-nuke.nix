{
  picoBoard ? "waveshare_rp2040_one",

  lib,
  stdenv,
  fetchFromGitHub,

  cmake,
  gcc-arm-embedded,
  picotool,
  python3,
  pico-sdk-full,
}:

stdenv.mkDerivation rec {
  pname = "pico-nuke";
  version = "1.4";

  src = fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-nuke";
    rev = "v${version}";
    hash = "sha256-qpNxdR7Pr7ch8XHp4mLA45/AJjMtElj/hVK0YXVngrA=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    gcc-arm-embedded
    picotool
    python3
  ];

  phases = [
    "unpackPhase"
    "configurePhase"
    "buildPhase"
    "installPhase"
  ];

  cmakeFlags =
    [
      (lib.cmakeFeature "CMAKE_CXX_COMPILER" "${gcc-arm-embedded}/bin/arm-none-eabi-g++")
      (lib.cmakeFeature "CMAKE_C_COMPILER" "${gcc-arm-embedded}/bin/arm-none-eabi-gcc")
      (lib.cmakeFeature "PICO_SDK_PATH" "${pico-sdk-full}/lib/pico-sdk")

      (lib.cmakeFeature "PICO_BOARD" picoBoard)
    ]
    ];

  installPhase = ''
    ${lib.optionalString (picoBoard != null) "mv flash_nuke.uf2 flash_nuke_${picoBoard}-${version}.uf2"}
    mkdir -p $out
    cp -r *.uf2 $out
  '';

  meta = {
    description = "Raspberry Pi flash nuke to reset the flash to all 0s for all supported boards";
    homepage = "https://github.com/polhenarejos/pico-nuke";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ vizid ];
  };
}
