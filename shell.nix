{
  pkgs ? import (import ./npins).nixpkgs { },
}:

pkgs.mkShell {
  packages =
    let
      update-nixpkgs = pkgs.writeShellApplication {
        name = "update-nixpkgs";
        runtimeInputs = with pkgs; [
          npins
        ];
        text = ''
          npins remove nixpkgs && \
          npins import-flake -n nixpkgs && \
          npins freeze nixpkgs
        '';
      };
      update-pico-packages = pkgs.writeShellApplication {
        name = "update-pico-packages";
        runtimeInputs = with pkgs; [
          npins
        ];
        text = ''
          npins update pico-fido pico-fido-latest \
          pico-fido2-latest pico-hsm  \
          pico-hsm-latest pico-nuke \
          pico-nuke-latest pico-openpgp \
          pico-openpgp-latest
        '';
      };
    in
    [
      pkgs.npins
      update-nixpkgs
      update-pico-packages
    ];
}
