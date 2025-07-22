{
  lib,
  fetchFromGitHub,

  buildPicoRom,

  picoBoard ? null,
  usbVid ? null,
  usbPid ? null,
  vidPid ? null,
  delayedBoot ? null,
  eddsaSupport ? null,
  secureBootKey ? null,

  ...
}:
buildPicoRom (
  lib.fix (final: {
    pname = "pico-fido";
    version = "6.6";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      rev = "v${final.version}";
      hash = "sha256-Fp3JMzN8Y5O25ldtAC9AvTaoLOX9RoUYXD+5Fk1Hp5I=";
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
      description = "Hardware Security Module (HSM) for Raspberry Pico and ESP32 ";
      homepage = "https://github.com/polhenarejos/pico-hsm";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [
        vizid
        nukdokplex
      ];
    };
  })
)
