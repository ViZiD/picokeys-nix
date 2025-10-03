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
    pname = "pico-hsm";
    version = "5.6";

    src = fetchFromGitHub {
      owner = "polhenarejos";
      repo = final.pname;
      rev = "v${final.version}";
      hash = "sha256-hKKcBZvab++ghBsMndUxRl/fAjgv+vO2ZgwIdLTeDfg=";
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
      description = "Transforming a Raspberry Pico into a FIDO Passkey";
      homepage = "https://github.com/polhenarejos/pico-fido2";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [
        vizid
        nukdokplex
      ];
    };
  })
)
