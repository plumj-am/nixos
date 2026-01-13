{ pkgs, lib, config, ... }: let
  inherit (lib) mkIf;
in {
  environment.systemPackages = mkIf config.isDesktop [
    pkgs.cabal-install
    pkgs.haskell.compiler.ghc912
    pkgs.haskellPackages.hlint
    pkgs.stack
  ];
}
