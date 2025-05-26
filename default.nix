let
  sources = import ./npins;
in
{
  system ? builtins.currentSystem,
  nixpkgs ? sources.nixpkgs,
}:
let
  pkgs = import nixpkgs {
    inherit system;
  };

  lib = pkgs.lib.extend (import ./lib.nix);

  pico-sdk = pkgs.callPackage ./pkgs/pico-sdk.nix {
    inherit sources lib;
  };
  picotool = pkgs.callPackage ./pkgs/picotool.nix { inherit pico-sdk sources lib; };
  pico-keys-sdk = pkgs.callPackage ./pkgs/pico-keys-sdk/default.nix { inherit sources lib; };

  callPkgWithSdk = pkgs.lib.callPackageWith (
    pkgs
    // {
      inherit
        pico-keys-sdk
        picotool
        sources
        lib
        ;
      pico-sdk-full = pico-sdk.override {
        withSubmodules = true;
      };
    }
  );

  pico-hsm-packages = callPkgWithSdk ./pkgs/pico-hsm-packages.nix { };
  pico-hsm-packages-nightly = callPkgWithSdk ./pkgs/pico-hsm-packages.nix { nightly = true; };

  pico-fido-packages = callPkgWithSdk ./pkgs/pico-fido-packages.nix { };
  pico-fido-packages-nightly = callPkgWithSdk ./pkgs/pico-fido-packages.nix { nightly = true; };
in
rec {
  inherit picotool;

  overlays = import ./overlays;

  pycvc = pkgs.callPackage ./pkgs/pycvc.nix { };
  pypicohsm = pkgs.callPackage ./pkgs/pypicohsm.nix { inherit pycvc; };

  pico-openpgp = callPkgWithSdk ./pkgs/pico-openpgp.nix { };
  pico-openpgp-nightly = callPkgWithSdk ./pkgs/pico-openpgp.nix { nightly = true; };

  pico-fido2 = callPkgWithSdk ./pkgs/pico-fido2.nix { };

  pico-hsm = pkgs.callPackage pico-hsm-packages.pico-hsm { };
  pico-hsm-tool = pkgs.callPackage (pico-hsm-packages.pico-hsm-tool) {
    inherit pycvc pypicohsm;
  };

  pico-hsm-nightly = pkgs.callPackage pico-hsm-packages-nightly.pico-hsm { };
  pico-hsm-tool-nightly = pkgs.callPackage (pico-hsm-packages-nightly.pico-hsm-tool) {
    inherit pycvc pypicohsm;
  };

  pico-fido = pkgs.callPackage pico-fido-packages.pico-fido { };
  pico-fido-tool = pico-fido-packages.pico-fido-tool;

  pico-fido-nightly = pkgs.callPackage pico-fido-packages-nightly.pico-fido { };
  pico-fido-tool-nightly = pico-fido-packages-nightly.pico-fido-tool;

  pico-nuke = callPkgWithSdk ./pkgs/pico-nuke.nix { };
  pico-nuke-nightly = callPkgWithSdk ./pkgs/pico-nuke.nix { nightly = true; };
}
