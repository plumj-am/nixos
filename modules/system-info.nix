{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.system-info;
}
