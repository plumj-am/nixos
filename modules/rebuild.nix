{ self, ... }:
{
  flake.modules.common.default = self.modules.common.rebuild;
  flake.modules.common.rebuild =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton self.packages.${pkgs.stdenv.hostPlatform.system}.rebuild;
    };
}
