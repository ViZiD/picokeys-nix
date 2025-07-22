{
  lib,
  lib',

  stdenv,

  cmake,
  gcc-arm-embedded,
  picotool,
  python3,
  pico-sdk,

  mbedtls-eddsa-src,

  ...
}:
(
  {
    pname,
    version,

    picoBoard ? "waveshare_rp2040_one",
    usbVid ? null,
    usbPid ? null,
    vidPid ? null,
    delayedBoot ? false,
    eddsaSupport ? false,
    secureBootKey ? null,

    mbedtls-eddsa-src-custom ? mbedtls-eddsa-src,

    ...
  }@attrs:
  (
    (stdenv.mkDerivation {
      inherit pname version;

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

        ${lib.optionalString eddsaSupport "rm -rf ./pico-keys-sdk/mbedtls && cp --no-preserve=mode -r ${mbedtls-eddsa-src-custom} ./pico-keys-sdk/mbedtls"}
        chmod -R +w ./pico-keys-sdk/mbedtls

        cat >> ./pico-keys-sdk/pico_keys_sdk_import.cmake <<'EOF'
        if (SECURE_BOOT_PKEY)
          pico_set_otp_key_output_file(''${CMAKE_PROJECT_NAME} otp.json) 
        endif()
        EOF

        runHook postPatch
      '';

      installPhase =
        let
          romName = lib'.genRomName {
            inherit
              picoBoard
              vidPid
              usbVid
              usbPid
              eddsaSupport
              pname
              version
              ;
          };
        in
        ''
          runHook preInstall

            find . -name "*.uf2" -type f -exec install -DT "{}" "$out/${romName}.uf2" \; -quit
            ${lib.optionalString (secureBootKey != null) "install otp.json $out"}

            runHook postInstall        
        '';
    }).overrideAttrs
    attrs
  )
)
