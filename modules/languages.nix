{
  config.flake.modules.nixos.haskell =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.cabal-install
        pkgs.haskell.compiler.ghc912
        pkgs.haskellPackages.hlint
        pkgs.stack
      ];
    };

  config.flake.modules.javascript =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bun
      ];
    };
}
