{
  description = "Flake for build Pico HSM/OpenPGP frimware";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unfree,
      flake-utils,
    }:
    let
      out =
        system:
        let
          pkgs = nixpkgs-unfree.legacyPackages.${system};
          appliedOverlay = self.overlays.default pkgs pkgs;
          shell =
            {
              mkShell,
              cmake,
              gcc-arm-embedded,
              pico-sdk,
              picotool,
              pico-hsm-tool,
              pycvc,
              pypicohsm,
            }:
            mkShell {
              packages = [
                cmake
                gcc-arm-embedded
                pico-sdk
                picotool
                pico-hsm-tool
                pycvc
                pypicohsm
              ];
            };
        in
        {
          packages = {
            inherit (appliedOverlay.picokeysPackages)
              pico-sdk
              pico-sdk-minimal
              picotool
              pycvc
              pypicohsm
              pico-openpgp
              pico-hsm
              pico-hsm-tool
              ;
          };

          devShell = appliedOverlay.picokeysPackages.callPackage shell { };
        };
    in
    flake-utils.lib.eachDefaultSystem out
    // {
      overlays.default = final: prev: {
        picokeysPackages = final.callPackage ./pkgs { };
        inherit (final.picokeysPackages)
          pico-sdk
          pico-sdk-minimal
          picotool
          pycvc
          pypicohsm
          pico-openpgp
          pico-hsm
          pico-hsm-tool
          ;
      };
    };
}
