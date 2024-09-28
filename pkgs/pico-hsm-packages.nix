{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
}:

let
  version = "4.2";
  source = fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-hsm";
    rev = "v${version}";
    hash = "sha256-iVlmFmYoyOerR8WUG7525bN8nxgbFoHDdLcucwHWdfg=";
    fetchSubmodules = true;
  };
  pico-hsm =
    {
      cmake,
      pico-sdk,
      picotool,
      gcc-arm-embedded,

      picoBoard ? null,
      usbVid ? null,
      usbPid ? null,
      vidPid ? null,
    }:
    stdenv.mkDerivation {
      pname = "pico-hsm";

      inherit version;

      src = source;

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
        ]
        ++ lib.optional (vidPid != null) [ "-DVIDPID=${vidPid}" ];

      installPhase = ''
        ${lib.optionalString (picoBoard != null)
          "mv pico_hsm.uf2 pico_hsm_${
            lib.optionalString (vidPid != null) "${vidPid}-"
          }${picoBoard}-${version}.uf2"
        }
        ${lib.optionalString (
          vidPid != null && picoBoard == null
        ) "mv pico_hsm.uf2 pico_hsm_${vidPid}-${version}.uf2"}
        mkdir -p $out
        cp -r *.uf2 $out
      '';

      meta = {
        description = "Hardware Security Module (HSM) for Raspberry Pico and ESP32";
        homepage = "https://github.com/polhenarejos/pico-hsm";
        license = lib.licenses.gpl3Only;
        maintainers = with lib.maintainers; [ vizid ];
      };
    };
  pico-hsm-tool =
    {
      pycvc,
      pypicohsm,
    }:
    stdenv.mkDerivation {
      pname = "pico-hsm-tool";
      inherit version;

      src = source;

      propagatedBuildInputs = [
        (python3.withPackages (
          pp: with pp; [
            cryptography
            pycvc
            pypicohsm
          ]
        ))
      ];

      installPhase = "install -Dm755 $src/tools/pico-hsm-tool.py $out/bin/pico-hsm-tool";

      meta = {
        description = "Tool for interacting with the Pico HSM";
        homepage = "https://github.com/polhenarejos/pico-hsm";
        license = lib.licenses.gpl3Only;
        maintainers = with lib.maintainers; [ vizid ];
      };
    };
in
{
  inherit pico-hsm pico-hsm-tool;
}
