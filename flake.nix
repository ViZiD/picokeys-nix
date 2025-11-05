{
  description = "Flake for build Pico HSM/OpenPGP/Fido firmware";
  inputs = {
    # failing builds
    # lock on picotool 2.1.1
    nixpkgs.url = "github:NixOS/nixpkgs?ref=fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec";

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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
          ./nix
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
