final: prev: rec {
  pico-sdk = prev.callPackage ./pkgs/picosdk.nix { };
  pico-sdk-minimal = prev.callPackage ./pkgs/picosdk.nix {
    minimal = true;
    picotool = null;
  };
  picotool = prev.callPackage ./pkgs/picotool.nix { };

  pycvc = prev.callPackage ./pkgs/pycvc.nix { };
  pypicohsm = prev.callPackage ./pkgs/pypicohsm.nix { };

  idf-components = prev.callPackage ./pkgs/idf-components.nix { };
  esp-idf =
    (final.esp-idf-esp32s3.override {
      rev = "46acfdce969f03c02b001fe4d24fa9e98f6adc5e";
      sha256 = "sha256-fH3XlJCsuP7++l48JptDPNZhcXhXJGSbuqeXDBIfj6Q=";
    }).overrideAttrs
      (old: {
        propagatedBuildInputs =
          (old.propagatedBuildInputs or [ ])
          ++ (with final.python3.pkgs; [
            rich
            psutil
          ]);
      });

  pico-openpgp-packages = prev.callPackage ./pkgs/pico-openpgp.nix { };
  pico-openpgp = prev.callPackage (pico-openpgp-packages.pico) { };
  pico-openpgp-esp32 = prev.callPackage (pico-openpgp-packages.esp32) {
    inherit idf-components esp-idf;
  };

  pico-hsm-packages = prev.callPackage ./pkgs/pico-hsm-packages.nix { };
  pico-hsm = prev.callPackage (pico-hsm-packages.pico-hsm) { };
  pico-hsm-tool = prev.callPackage (pico-hsm-packages.pico-hsm-tool) { };

  pico-nuke = prev.callPackage ./pkgs/pico-nuke.nix { };

  pico-fido-packages = prev.callPackage ./pkgs/pico-fido-packages.nix { };
  pico-fido = prev.callPackage (pico-fido-packages.pico-fido) { };
  pico-fido-tool = pico-fido-packages.pico-fido-tool;
}
