{
  description = "Flake for build Pico HSM/OpenPGP/Fido firmware";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    systems.url = "github:nix-systems/default-linux";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-compat.url = "https://github.com/edolstra/flake-compat/archive/refs/tags/v1.1.0.tar.gz";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { inputs, config, ... }:
      {
        imports = [
          inputs.pkgs-by-name-for-flake-parts.flakeModule
          ./devshells.nix
          ./overlays.nix
          ./lib.nix
        ];

        systems = import inputs.systems;

        perSystem =
          { system, ... }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ config.flake.overlays.lib ];
            };
            pkgsDirectory = ./pkgs;
          };
      }
    );
}
