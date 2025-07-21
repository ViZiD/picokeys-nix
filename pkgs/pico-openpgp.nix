{
  lib,
  lib',
  fetchFromGitHub,

  stdenv,

  cmake,
  gcc-arm-embedded,
  picotool,
  python3,
  pico-sdk,

  mbedtls-eddsa-src,

  picoBoard ? "waveshare_rp2040_one",
  usbVid ? null,
  usbPid ? null,
  vidPid ? null,
  delayedBoot ? false,
  eddsaSupport ? false,
  secureBootKey ? null,

  ...
}:
stdenv.mkDerivation (
  final:
  let
    romName = lib'.genRomName {
      inherit
        picoBoard
        vidPid
        usbVid
        usbPid
        eddsaSupport
        ;
      inherit (final)
        pname
        version
        ;
    };
  in
  {
    pname = "pico-openpgp";
    version = "3.6";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      rev = "v${final.version}";
      hash = "sha256-w0rt7oFzv1H4KZIVABjJ2CNLlfMGOrBL6nIoq6IfGao=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      cmake
      gcc-arm-embedded
      picotool
      python3
    ];

    cmakeFlags =
      [
        (lib.cmakeFeature "CMAKE_CXX_COMPILER" "${gcc-arm-embedded}/bin/arm-none-eabi-g++")
        (lib.cmakeFeature "CMAKE_C_COMPILER" "${gcc-arm-embedded}/bin/arm-none-eabi-gcc")
        (lib.cmakeFeature "PICO_SDK_PATH" "${pico-sdk.override { withSubmodules = true; }}/lib/pico-sdk")

        (lib.cmakeFeature "PICO_BOARD" picoBoard)
        (lib.cmakeBool "ENABLE_DELAYED_BOOT" delayedBoot)
        (lib.cmakeBool "ENABLE_EDDSA" eddsaSupport)
      ]
      ++ lib.optionals (usbVid != null && usbPid != null) [
        (lib.cmakeFeature "USB_VID" usbVid)
        (lib.cmakeFeature "USB_PID" usbPid)
      ]
      ++ lib.optional (vidPid != null) (lib.cmakeFeature "VIDPID" vidPid)
      ++ lib.optional (secureBootKey != null) (lib.cmakeFeature "SECURE_BOOT_PKEY" secureBootKey);

    patchPhase = ''
      runHook prePatch

      ${lib.optionalString eddsaSupport "rm -rf ./pico-keys-sdk/mbedtls && cp --no-preserve=mode -r ${mbedtls-eddsa-src} ./pico-keys-sdk/mbedtls"}
      cat >> ./pico-keys-sdk/pico_keys_sdk_import.cmake <<'EOF'
      if (SECURE_BOOT_PKEY)
        pico_set_otp_key_output_file(''${CMAKE_PROJECT_NAME} otp.json) 
      endif()
      EOF

      runHook postPatch
    '';

    installPhase = ''
      runHook preInstall

      find . -name "*.uf2" -type f -exec install -DT "{}" "$out/${romName}.uf2" \; -quit
      ${lib.optionalString (secureBootKey != null) "install otp.json $out"}

      runHook postInstall        
    '';

    meta = {
      description = "Transforming a Raspberry Pico into a FIDO Passkey";
      homepage = "https://github.com/polhenarejos/pico-fido";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ vizid ];
    };
  }
)
