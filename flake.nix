{
  description = "Flake for build Pico HSM/OpenPGP/Fido firmware";
  inputs = {
    # failing builds
    # lock on picotool 2.1.1
    nixpkgs.url = "github:NixOS/nixpkgs?ref=fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec";
    flake-compat.url = "https://github.com/edolstra/flake-compat/archive/refs/tags/v1.1.0.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
      treefmt-nix,
      ...
    }:
    {
      overlays = import ./overlays.nix { inherit (inputs) outputs; };
    }
    // flake-utils.lib.eachSystem nixpkgs.lib.systems.flakeExposed (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.lib ];
        };

        legacyPackages = pkgs.lib.filesystem.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage newScope;
          directory = ./pkgs;
        };
        packages = nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) self.legacyPackages.${system};

        treefmt = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          settings.global.excludes = [
            "*.md"
            ".envrc"
            ".gitlint"
          ];
          programs = {
            nixfmt.enable = true;
            deadnix.enable = true;
            statix.enable = true;
          };
        };

        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            gitlint.enable = true; # lint commit messages
            # run all formatters
            treefmt = {
              enable = true;
              package = self.formatter.${system};
            };
          };
        };
        inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
      in
      {
        inherit legacyPackages packages;
        devShells.default = pkgs.mkShell {
          inherit shellHook;
          buildInputs = enabledPackages;
          packages = [ pkgs.nix-prefetch-github ];
        };
        checks = {
          inherit pre-commit-check;
          formatting = treefmt.config.build.check self;
        };
        formatter = treefmt.config.build.wrapper;
      }
    );
}
