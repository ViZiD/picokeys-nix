{
  pkgs ? import (import ./npins).nixpkgs { },
}:
let
  sources = import ./npins;

  lib = pkgs.lib.extend (import ./lib.nix);

  callPackage = pkgs.newScope {
    inherit
      pico-keys-sdk
      pico-sdk
      picotool
      sources
      lib
      callPackage
      ;
    pico-sdk-full = pico-sdk.override {
      withSubmodules = true;
    };
  };

  pico-sdk = callPackage ./pkgs/pico-sdk.nix { };
  picotool = callPackage ./pkgs/picotool.nix { };

  pico-keys-sdk = callPackage ./pkgs/pico-keys-sdk/default.nix { };

  pico-hsm-packages = callPackage ./pkgs/pico-hsm-packages.nix { };
  pico-hsm-packages-nightly = callPackage ./pkgs/pico-hsm-packages.nix { nightly = true; };

  pico-fido-packages = callPackage ./pkgs/pico-fido-packages.nix { };
  pico-fido-packages-nightly = callPackage ./pkgs/pico-fido-packages.nix { nightly = true; };
in
rec {
  inherit picotool;

  overlays = import ./overlays;

  pycvc = callPackage ./pkgs/pycvc.nix { };
  pypicohsm = callPackage ./pkgs/pypicohsm.nix { inherit pycvc; };

  pico-openpgp = callPackage ./pkgs/pico-openpgp.nix { };
  pico-openpgp-nightly = callPackage ./pkgs/pico-openpgp.nix { nightly = true; };

  pico-fido2 = callPackage ./pkgs/pico-fido2.nix { };

  pico-hsm = callPackage pico-hsm-packages.pico-hsm { };
  pico-hsm-tool = callPackage (pico-hsm-packages.pico-hsm-tool) {
    inherit pycvc pypicohsm;
  };

  pico-hsm-nightly = callPackage pico-hsm-packages-nightly.pico-hsm { };
  pico-hsm-tool-nightly = callPackage (pico-hsm-packages-nightly.pico-hsm-tool) {
    inherit pycvc pypicohsm;
  };

  pico-fido = callPackage pico-fido-packages.pico-fido { };
  pico-fido-tool = pico-fido-packages.pico-fido-tool;

  pico-fido-nightly = callPackage pico-fido-packages-nightly.pico-fido { };
  pico-fido-tool-nightly = pico-fido-packages-nightly.pico-fido-tool;

  pico-nuke = callPackage ./pkgs/pico-nuke.nix { };
  pico-nuke-nightly = callPackage ./pkgs/pico-nuke.nix { nightly = true; };
}
