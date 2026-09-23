{ self, ... }:
{
  flake.modules.common.desktop = self.modules.common.haskell;
  flake.modules.common.haskell =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.cabal-install
        pkgs.haskellPackages.cabal-fmt
        # pkgs.haskell.compiler.ghc912
        pkgs.haskell.compiler.ghc9103
        pkgs.haskellPackages.hlint
      ];

      hjem.extraModule = {
        xdg.config.files."fourmolu.yaml".text = # yaml
          ''
            indentation: 3
            column-limit: 100
          '';
      };
    };
}
