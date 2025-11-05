{ outputs, ... }:
rec {
  packages = _: prev: {
    picokeysPackages = outputs.legacyPackages.${prev.stdenv.hostPlatform.system} or { };
  };

  lib = import ./lib.nix;

  default = packages;
}
