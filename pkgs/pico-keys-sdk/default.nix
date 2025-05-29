{
  lib,
  stdenvNoCC,
  callPackage,
  sources,
}:
lib.makeOverridable (
  {
    eddsaSupport ? false,
    generateOtpFile ? false,
  }:
  let
    mbedtls = callPackage ./mbedtls.nix { } { inherit eddsaSupport; };
    tinycbor = callPackage ./tinycbor.nix { };
  in
  stdenvNoCC.mkDerivation {
    pname = "pico-keys-sdk";
    version = (lib.mkSourceVersion sources.pico-keys-sdk true);

    src = sources.pico-keys-sdk;

    prePatch = lib.optionalString generateOtpFile ''
      sed -i -e '/pico_hash_binary(''${CMAKE_PROJECT_NAME})/a\
      pico_set_otp_key_output_file(''${CMAKE_PROJECT_NAME} otp.json)' pico_keys_sdk_import.cmake
    '';

    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/pico-keys-sdk
      cp -r . $out/share/pico-keys-sdk
      cp -r "${tinycbor}/share/tinycbor" $out/share/pico-keys-sdk
      cp -r "${mbedtls}/share/mbedtls" $out/share/pico-keys-sdk
      runHook postInstall
    '';

    meta = {
      description = "Core functionalities to transform Raspberry Pico into a CCID device";
      homepage = "https://github.com/polhenarejos/pico-keys-sdk";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ vizid ];
    };
  }
)
