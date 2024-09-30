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

}
