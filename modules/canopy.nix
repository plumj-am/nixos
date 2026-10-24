{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.canopy;
  flake.modules.nixos.canopy =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}; [
        canopy-canopy-bar
      ];
    };
}
