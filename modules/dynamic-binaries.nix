{ self, ... }:
{
  flake.nixosModules.default = self.nixosModules.dynamic-binaries;
  flake.nixosModules.dynamic-binaries = {
    programs.nix-ld.enable = true;
  };
}
