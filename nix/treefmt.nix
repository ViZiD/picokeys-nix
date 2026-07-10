{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem =
    { config, ... }:
    {
      treefmt.config = {
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

      formatter = config.treefmt.build.wrapper;
    };
}
