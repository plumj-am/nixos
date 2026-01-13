{
  flake.modules.nixos.haskell =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.cabal-install
        pkgs.haskell.compiler.ghc912
        pkgs.haskellPackages.hlint
        pkgs.stack
      ];
    };

  flake.modules.nixos.javascript =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bun
      ];
    };
}
