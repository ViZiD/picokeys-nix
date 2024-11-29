{
  description = "Flake for build Pico HSM/OpenPGP/Fido firmware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      overlays.default = import ./overlay.nix;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (pkgs.lib.getName pkg) [
              "pico-sdk"
            ];
        };
      in
      {
        packages = {
          inherit (pkgs)
            pycvc
            pypicohsm
            pico-openpgp
            pico-openpgp-eddsa
            pico-hsm
            pico-hsm-tool
            pico-nuke
            pico-fido
            pico-fido-tool
            ;
        };
      }
    );
}
