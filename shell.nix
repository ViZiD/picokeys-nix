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
      update-pico-latest = pkgs.writeShellApplication {
        name = "update-pico-latest";
        runtimeInputs = with pkgs; [
          npins
        ];
        text = ''
          npins update pico-fido-latest pico-fido2-latest pico-keys-sdk \
          pico-hsm-latest pico-nuke-latest pico-openpgp-latest
        '';
      };
      update-pico = pkgs.writeShellApplication {
        name = "update-pico";
        runtimeInputs = with pkgs; [
          npins
        ];
        text = ''
          npins update pico-fido pico-hsm pico-nuke pico-openpgp
        '';
      };
    in
    [
      pkgs.npins
      update-nixpkgs
      update-pico-latest
      update-pico
    ];
}
