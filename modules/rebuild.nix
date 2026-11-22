{ self, ... }:
{
  flake.commonModules.default = self.commonModules.rebuild;
  flake.commonModules.rebuild =
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
