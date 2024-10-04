{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

let
  pname = "pico-openpgp";
  source =
    { rev, hash }:
    fetchFromGitHub {
      owner = "polhenarejos";
      repo = "pico-openpgp";
      inherit rev hash;
      fetchSubmodules = true;
    };
  meta = {
    description = "Converting a Raspberry Pico into an OpenPGP CCID smart card";
    homepage = "https://github.com/polhenarejos/pico-openpgp";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ vizid ];
  };
  pico =
    {
      rev ? "v2.2",
      hash ? "sha256-XqZNpkwRrSKxizW11gVdiBB1R9ijeIOckqojOF1BU8k=",
      picoBoard ? "waveshare_rp2040_one",
      usbVid ? null,
      usbPid ? null,
      vidPid ? null,

      pico-sdk,
      picotool,
      gcc-arm-embedded,
      python3,
    }:
    stdenv.mkDerivation rec {
      version = rev;

      inherit meta pname;

      src = source { inherit rev hash; };

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
          "mv pico_openpgp.uf2 pico_openpgp_${
            lib.optionalString (vidPid != null) "${vidPid}-"
          }${picoBoard}-${version}.uf2"
        }
        ${lib.optionalString (
          vidPid != null && picoBoard == null
        ) "mv pico_openpgp.uf2 pico_openpgp_${vidPid}-${version}.uf2"}

        mkdir -p $out
        cp -r *.uf2 $out
      '';
    };
  esp32 =
    {
      rev ? "442caa271628fdd56b905d3e1222d40ba09a6fef",
      hash ? "sha256-IKhpLI/4xn80vBSJdUa5Xpuf/y5kCOZIQf8GWaRog3k=",
      usbVid ? null,
      usbPid ? null,
      vidPid ? null,

      esp-idf,
      idf-components,
    }:
    stdenv.mkDerivation {
      version = rev;

      inherit meta pname;

      src = source { inherit rev hash; };

      buildInputs = [
        esp-idf
      ];

      phases = [
        "unpackPhase"
        "buildPhase"
        "installPhase"
      ];

      cmakeFlags =
        [
          "-DESP_PLATFORM=1"
        ]
        ++ lib.optional (usbVid != null) [
          "-DUSB_VID=${usbVid}"
        ]
        ++ lib.optional (usbPid != null) [
          "-DUSB_PID=${usbPid}"
        ]
        ++ lib.optional (vidPid != null) [ "-DVIDPID=${vidPid}" ];

      preBuildPhase = ''
        mkdir -p managed_components
        cp -r ${idf-components}/* managed_components
        chmod -R +w managed_components/*
        mkdir temp-home
        export HOME=$(readlink -f temp-home)
        export IDF_COMPONENT_MANAGER=0
      '';

      buildPhase = ''
        runHook preBuildPhase
        idf.py set-target esp32s3
        idf.py build
      '';

      installPhase = ''
        mkdir -p $out
        cp -r *.uf2 $out
      '';
    };
in
{
  inherit pico esp32;
}
