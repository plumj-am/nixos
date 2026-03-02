let
  lixBase =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) remove;
    in
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
        settings.experimental-features = [ "pipe-operator" ] |> remove [ "pipe-operators" ];

        package = pkgs.lixPackageSets.latest.lix;
      };
    };
in
{
  flake.modules.nixos.lix = lixBase;
  flake.modules.darwin.lix = lixBase;
}
