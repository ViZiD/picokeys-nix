{
  perSystem =
    { pkgs, config, ... }:
    {
      devShells.develop = pkgs.mkShell {
        shellHook = config.pre-commit.installationScript;

        packages = with pkgs; [ nix-prefetch-github ] ++ config.pre-commit.settings.enabledPackages;
      };
    };
}
