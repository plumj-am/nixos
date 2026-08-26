{ self, ... }:
{
  flake.modules.common.default = self.modules.common.rebuild;
  flake.modules.common.rebuild =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.default # nh
        self.packages.${pkgs.stdenv.hostPlatform.system}.rebuild
      ];
    };
}
