{
  flake.modules.common.tack =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages =
        singleton
          inputs.tack.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
}
