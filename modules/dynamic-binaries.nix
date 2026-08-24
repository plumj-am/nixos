{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.dynamic-binaries;
  flake.modules.nixos.dynamic-binaries = {
    programs.nix-ld.enable = true;
  };
}
