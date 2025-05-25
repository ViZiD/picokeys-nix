{

  picoBoard ? "waveshare_rp2040_one",
  usbVid ? null,
  usbPid ? null,
  vidPid ? null,
  delayedBoot ? false,
  eddsaSupport ? false,
  secureBootKey ? null,
  generateOtpFile ? false,
  nightly ? true,

  lib,
  stdenv,
  cmake,
  pico-sdk-full,
  picotool,
  gcc-arm-embedded,
  python3,

  pico-keys-sdk,
  sources,
}:
stdenv.mkDerivation rec {
  pname = "pico_fido2${lib.optionalString eddsaSupport "-eddsa"}${lib.optionalString nightly "-nightly"}";

  src = if nightly then sources.pico-fido2-latest else sources.pico-fido2-latest; # FIXME: wait for releases
  version = (lib.mkSourceVersion src nightly);

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
      (lib.cmakeBool "ENABLE_DELAYED_BOOT" delayedBoot)
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
    cp -r ${sources.pico-openpgp-latest}/* pico-openpgp
    cp -r ${sources.pico-fido-latest}/* pico-fido

    chmod -R +w pico-keys-sdk
    chmod -R +w pico-openpgp
    chmod -R +w pico-fido
  '';

  installPhase = ''
    ${lib.optionalString (picoBoard != null)
      "mv pico_fido2.uf2 pico_fido2${lib.optionalString eddsaSupport "_eddsa"}_${
        lib.optionalString (vidPid != null) "${vidPid}-"
      }${picoBoard}-${version}.uf2"
    }
    ${lib.optionalString (vidPid != null && picoBoard == null)
      "mv pico_fido2.uf2 pico_fido2${lib.optionalString eddsaSupport "_eddsa"}_${vidPid}-${version}.uf2"
    }

    mkdir -p $out
    cp *.uf2 $out
    runHook postInstall
  '';

  postInstall = lib.optionalString generateOtpFile ''
    cp otp.json $out
  '';

  meta = {
    description = "Pico Fido + Pico OpenPGP";
    homepage = "https://github.com/polhenarejos/pico-fido2";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ vizid ];
  };
}
