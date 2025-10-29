{ inputs, self, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      pre-commit.settings.hooks = {
        gitlint.enable = true;

        treefmt = {
          package = self.formatter.${pkgs.system};
          enable = true;
        };
      };
    };
}
