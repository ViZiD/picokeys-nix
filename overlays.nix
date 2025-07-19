{ inputs, config, ... }:
{
  flake.overlays = {
    packages = _: prev: {
      picokeysPackages = inputs.self.outputs.legacyPackages.${prev.stdenv.hostPlatform.system} or { };
    };

    lib = _: _: {
      lib' = config.flake.lib;
    };

    default = config.overlays.packages;
  };
}
