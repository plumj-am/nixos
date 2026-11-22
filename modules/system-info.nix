{ self, ... }:
{
  flake.nixosModules.default = self.nixosModules.system-info;
}
