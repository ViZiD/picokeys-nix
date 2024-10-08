final: prev: rec {
  pico-sdk = prev.callPackage ./pkgs/picosdk.nix { };
  pico-sdk-minimal = prev.callPackage ./pkgs/picosdk.nix {
    minimal = true;
    picotool = null;
  };
  picotool = prev.callPackage ./pkgs/picotool.nix { };

  pycvc = prev.callPackage ./pkgs/pycvc.nix { };
  pypicohsm = prev.callPackage ./pkgs/pypicohsm.nix { };

  pico-openpgp = prev.callPackage ./pkgs/pico-openpgp.nix { };

  pico-hsm-packages = prev.callPackage ./pkgs/pico-hsm-packages.nix { };
  pico-hsm = prev.callPackage (pico-hsm-packages.pico-hsm) { };
  pico-hsm-tool = prev.callPackage (pico-hsm-packages.pico-hsm-tool) { };

  pico-nuke = prev.callPackage ./pkgs/pico-nuke.nix { };

  pico-fido-packages = prev.callPackage ./pkgs/pico-fido-packages.nix { };
  pico-fido = prev.callPackage (pico-fido-packages.pico-fido) { };
  pico-fido-tool = pico-fido-packages.pico-fido-tool;
}
