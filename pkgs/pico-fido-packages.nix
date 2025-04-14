{
  lib,
  stdenv,
  fetchFromGitHub,

  python3,
  cmake,
  pico-sdk-full,
  picotool,
  gcc-arm-embedded,

  pico-keys-sdk,
}:
let
  version = "6.6";
  src = fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-fido";
    rev = "v${version}";
    hash = "sha256-Em8QULTe+NlTeSYZe/pmfCPBABpLHrIyviOD8N4KX14=";
  };
  pico-fido =
    {
      picoBoard ? "waveshare_rp2040_one",
      usbVid ? null,
      usbPid ? null,
      vidPid ? null,
      eddsaSupport ? false,
      secureBootKey ? null,
      generateOtpFile ? false,
    }:
    stdenv.mkDerivation {
      pname = "pico-fido${lib.optionalString eddsaSupport "-eddsa"}";
      inherit version src;

      nativeBuildInputs = [
        cmake
        gcc-arm-embedded
        picotool
        python3
      ];

      phases = [
        "unpackPhase"
        "patchPhase"
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
          (lib.cmakeBool "ENABLE_EDDSA" eddsaSupport)
        ]
        ++ lib.optional (usbVid != null && usbPid != null) [
          (lib.cmakeFeature "USB_VID" usbVid)
          (lib.cmakeFeature "USB_PID" usbPid)
        ]
        ++ lib.optional (vidPid != null) [
          (lib.cmakeFeature "VIDPID" vidPid)
        ]
        ++ lib.optional (secureBootKey != null) [
          (lib.cmakeFeature "SECURE_BOOT_PKEY" secureBootKey)
        ];

      prePatch = ''
        cp -r ${pico-keys-sdk { inherit eddsaSupport generateOtpFile; }}/share/pico-keys-sdk .
        chmod -R +w pico-keys-sdk
      '';

      installPhase = ''
        ${lib.optionalString (picoBoard != null)
          "mv pico_fido.uf2 pico_fido${lib.optionalString eddsaSupport "_eddsa"}_${
            lib.optionalString (vidPid != null) "${vidPid}-"
          }${picoBoard}-${version}.uf2"
        }
        ${lib.optionalString (
          vidPid != null && picoBoard == null
        ) "mv pico_fido.uf2 pico_fido${lib.optionalString eddsaSupport "_eddsa"}_${vidPid}-${version}.uf2"}
        mkdir -p $out
        cp *.uf2 $out
        runHook postInstall        
      '';

      postInstall = lib.optionalString generateOtpFile ''
        cp /build/source/otp.json $out
      '';

      meta = {
        description = "Transforming a Raspberry Pico into a FIDO Passkey";
        homepage = "https://github.com/polhenarejos/pico-fido";
        license = lib.licenses.gpl3Only;
        maintainers = with lib.maintainers; [ vizid ];
      };
    };

  pico-fido-tool = python3.pkgs.buildPythonApplication rec {
    inherit src;
    pname = "pico-fido-tool";
    version = "1.8";
    pyproject = true;

    doCheck = false;

    sourceRoot = "source/tools";

    patchPhase = ''
      mv pico-fido-tool.py pico-fido-tool
      cat > setup.py <<EOF
      from setuptools import setup
      setup(
        name = "${pname}",
        version = "${version}",
        scripts = ["pico-fido-tool"],
        package_dir = {"": "."}
      )
      EOF
    '';

    build-system = [ python3.pkgs.setuptools ];

    dependencies = with python3.pkgs; [
      keyring
      cryptography
      fido2
    ];

    meta = {
      description = "Tool for interacting with the Pico Fido";
      homepage = "https://github.com/polhenarejos/pico-fido";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ vizid ];
    };
  };
in
{
  inherit pico-fido-tool pico-fido;
}
