{
  lib,
  fetchFromGitHub,

  buildPicoRom,

  picoBoard ? "waveshare_rp2040_one",
  usbVid ? null,
  usbPid ? null,
  vidPid ? null,
  delayedBoot ? false,
  eddsaSupport ? false,
  secureBootKey ? null,

  ...
}:
buildPicoRom (
  lib.fix (final: {
    pname = "pico-fido2";
    version = "6.6-unstable-2025-08-12";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      rev = "a296a388b915a1c522ea97cbab60ea7e5dc39f49";
      hash = "sha256-ugGfk66Q8uVaUf7f7o8+ipDRo75ZWWCdAeZk/6bxMj4=";
      fetchSubmodules = true;
    };

    inherit
      picoBoard
      usbVid
      usbPid
      vidPid
      delayedBoot
      eddsaSupport
      secureBootKey
      ;

    meta = {
      description = "Pico Fido + Pico OpenPGP ";
      homepage = "https://github.com/polhenarejos/pico-fido2";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [
        vizid
        nukdokplex
      ];
    };
  })
)
