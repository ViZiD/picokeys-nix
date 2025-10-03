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
    version = "6.6-unstable-2025-07-09";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      rev = "512d399fd02fb8827b347f9c70763f9fe1838414";
      hash = "sha256-UMOUmrjAAdJ9SbnR9aDcp36R2E0hbYf8u5XQO4JMgTM=";
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
