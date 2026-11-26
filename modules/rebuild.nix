{ self, ... }:
{
  flake.commonModules.default = self.commonModules.rebuild;
  flake.commonModules.rebuild =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.dix
        pkgs.nh

        inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.nom-rs
        self.packages.${pkgs.stdenv.hostPlatform.system}.default # rebuild etc.
      ];
    };
}
