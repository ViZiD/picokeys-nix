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
  secureBootKey ? null,

  ...
}:
stdenv.mkDerivation (
  final:
  let
    romName = lib'.genRomName {
      inherit
        picoBoard
        ;
      inherit (final)
        pname
        version
        ;
    };
  in
  {
    pname = "pico-nuke";
    version = "1.4";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      tag = "v${final.version}";
      hash = "sha256-qpNxdR7Pr7ch8XHp4mLA45/AJjMtElj/hVK0YXVngrA=";
    };

    nativeBuildInputs = [
      cmake
      gcc-arm-embedded
      picotool
      python3
    ];

    cmakeFlags = [
      (lib.cmakeFeature "CMAKE_CXX_COMPILER" "${gcc-arm-embedded}/bin/arm-none-eabi-g++")
      (lib.cmakeFeature "CMAKE_C_COMPILER" "${gcc-arm-embedded}/bin/arm-none-eabi-gcc")
      (lib.cmakeFeature "PICO_SDK_PATH" "${pico-sdk}/lib/pico-sdk")
      (lib.cmakeFeature "PICO_BOARD" picoBoard)
    ] ++ lib.optional (secureBootKey != null) (lib.cmakeFeature "SECURE_BOOT_PKEY" secureBootKey);

    prePatch = ''
      sed -i -e '/pico_hash_binary(''${CMAKE_PROJECT_NAME})/a\
      pico_set_otp_key_output_file(''${CMAKE_PROJECT_NAME} otp.json)' CMakeLists.txt
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
