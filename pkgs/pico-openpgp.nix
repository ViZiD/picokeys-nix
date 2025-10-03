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
    pname = "pico-openpgp";
    version = "3.6";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      rev = "v${final.version}";
      hash = "sha256-w0rt7oFzv1H4KZIVABjJ2CNLlfMGOrBL6nIoq6IfGao=";
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
      description = "OpenPGP CCID smart card for Raspberry Pico and ESP32.";
      homepage = "https://github.com/polhenarejos/pico-openpgp";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [
        vizid
        nukdokplex
      ];
    };
  })
)
