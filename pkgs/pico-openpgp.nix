{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pico-sdk,
  picotool,
  gcc-arm-embedded,
  python3,

  picoBoard ? null,
  usbVid ? null,
  usbPid ? null,
}:

stdenv.mkDerivation rec {
  pname = "pico-openpgp";
  version = "2.2";

  src = fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-openpgp";
    rev = "v${version}";
    hash = "sha256-XqZNpkwRrSKxizW11gVdiBB1R9ijeIOckqojOF1BU8k=";
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
      "-DPICO_SDK_PATH=${pico-sdk}/lib/pico-sdk"
      "-DCMAKE_C_COMPILER=${gcc-arm-embedded}/bin/arm-none-eabi-gcc"
      "-DCMAKE_CXX_COMPILER=${gcc-arm-embedded}/bin/arm-none-eabi-g++"
    ]
    ++ lib.optional (picoBoard != null) [
      "-DPICO_BOARD=${picoBoard}"
    ]
    ++ lib.optional (usbVid != null) [
      "-DUSB_VID=${usbVid}"
    ]
    ++ lib.optional (usbPid != null) [
      "-DUSB_PID=${usbPid}"
    ];

  installPhase = ''
    ${lib.optionalString (
      picoBoard != null
    ) "mv pico_openpgp.uf2 pico_openpgp_${picoBoard}-${version}.uf2"}
    mkdir -p $out
    cp -r *.uf2 $out
  '';

  meta = {
    description = "Converting a Raspberry Pico into an OpenPGP CCID smart card";
    homepage = "https://github.com/polhenarejos/pico-openpgp";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ vizid ];
  };
}
