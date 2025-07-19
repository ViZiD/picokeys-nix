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
    rev = "9b75c5c175a8ed263cf1ac7b3e5ddc92d5d23e24";
    hash = "sha256-D91pmauCMario/kwOxPavnE9Lu4xQyQ1EVt+fffF0zQ=";
  },
  pico-openpgp-src ? fetchFromGitHub {
    owner = "polhenarejos";
    repo = "pico-openpgp";
    rev = "f34cdac00b4c0c6515686f0b34d13065d1c9bcbd";
    hash = "sha256-o6IF9EhauVHLEUsLKKAVOgen6uzCj2B2Aau8opIvqag=";
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
          rev = "eb75ad4efa36703ed5dc7aaed1779e97497febb1";
          hash = "sha256-bjSNEgOeGvV9MP6lb9bbxJGvdbq6gpgvkkD48wsZpck=";
        };
        pico-keys-sdk-version = "7.0-unstable-2025-04-07";

        mbedtls-src =
          if eddsaSupport then
            fetchFromGitHub {
              owner = "polhenarejos";
              repo = "mbedtls";
              tag = "mbedtls-3.6-eddsa";
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
    version = "6.6";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      tag = "v${final.version}";
      hash = "sha256-za3hymEurUQarSvaD9DrYnhsFUhe8G2p+LONN/ag260=";
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
      sed -i -e '/pico_hash_binary(''${CMAKE_PROJECT_NAME})/a\
      pico_set_otp_key_output_file(''${CMAKE_PROJECT_NAME} otp.json)' ./pico-keys-sdk/pico_keys_sdk_import.cmake
      cat ./pico-keys-sdk/pico_keys_sdk_import.cmake
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
