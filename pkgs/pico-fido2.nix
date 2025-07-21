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

  picoBoard ? "waveshare_rp2040_one",
  usbVid ? null,
  usbPid ? null,
  vidPid ? null,
  delayedBoot ? false,
  eddsaSupport ? false,
  secureBootKey ? null,

  pico-keys-sdk,
  pico-keys-sdk-custom ? null,
  pico-fido-src ? fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-fido";
    rev = "9c28f72d176f94b5cc0fa0d7de5d7d38600631ff";
    hash = "sha256-35oTI8oUAsHIpMH+nZ8bLERn9a2vNpWdj8WS7E5ECvM=";
  },
  pico-openpgp-src ? fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-openpgp";
    rev = "41ae81067cb2ceb233144aa3d79cbce38d630967";
    hash = "sha256-WyxMxKwFIHPYCwy79ScOiXnUC+kXzvevQNYoDvrbVYs=";
  },

  ...
}:
let
  pico-keys-sdk-final =
    if pico-keys-sdk-custom != null then
      pico-keys-sdk-custom
    else
      pico-keys-sdk.override {
        pico-keys-sdk-src = fetchFromGitHub {
          owner = "polhenarejos";
          repo = "pico-keys-sdk";
          rev = "113e720fcaaa6b9ca74d114bee1923bb2619ba3b";
          hash = "sha256-KbE3rrJn9F0WwKztz+JRk+5GHP70wkqgUGdOfFkRDOM=";
        };
        pico-keys-sdk-version = "7.0-unstable-2025-06-22";

        mbedtls-src =
          if eddsaSupport then
            fetchFromGitHub {
              owner = "polhenarejos";
              repo = "mbedtls";
              rev = "6320af56726247352af5a003ae77f465f5b4f1c7";
              hash = "sha256-wntpAcUE6EQlzxqM8jQCHMxBympGB/RTwFecYd+YPJk=";
            }
          else
            fetchFromGitHub {
              owner = "Mbed-TLS";
              repo = "mbedtls";
              rev = "107ea89daaefb9867ea9121002fbbdf926780e98";
              hash = "sha256-CigOAezxk79SSTX6Z7rDnt64qI6nkCD0piY9ZVNy+e0=";
            };
      };
in
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
    pname = "pico-fido2";
    version = "6.6-unstable-2025-07-09";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      rev = "512d399fd02fb8827b347f9c70763f9fe1838414";
      hash = "sha256-lJTnJg/nkoCJhuAm7zu9LFbyVhnkG1jyhLThrObApSg=";
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

      cp --no-preserve=mode -r "${pico-keys-sdk-final}/share/pico-keys-sdk" .
      rm -rf pico-fido pico-openpgp
      cp --no-preserve=mode -r "${pico-fido-src}" pico-fido
      cp --no-preserve=mode -r "${pico-openpgp-src}" pico-openpgp

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
