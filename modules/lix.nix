let
  lixBase =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_final: prev: {
          inherit (prev.lixPackageSets.latest)
            nix-eval-jobs
            nix-fast-build
            nix-index
            nix-serve-ng
            colmena
            ;
        })
      ];

      nix = {
        package = pkgs.lixPackageSets.latest.lix;

        settings.max-connect-timeout = 30;
      };
    };
in
{
  flake.modules.nixos.lix = lixBase;
  flake.modules.darwin.lix = lixBase;
}
