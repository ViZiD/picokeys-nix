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
    tinycbor = callPackage ./tinycbor.nix { inherit sources; };
    mbedtls = callPackage ./mbedtls.nix { } { inherit eddsaSupport; };
  in
  stdenvNoCC.mkDerivation {
    pname = "pico-keys-sdk";
    version = sources.pico-keys-sdk.revision;

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
