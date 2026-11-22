{ self, ... }:
{
  flake.nixosModules.default = self.nixosModules.unfree;
  flake.nixosModules.unfree =
    { lib, config, ... }:
    let
      inherit (lib.lists) elem;
      inherit (lib.modules) mkIf;
      inherit (lib.strings) getName;

      inherit (config.systemInfo) gpu;
    in
    {

      config.nixpkgs.config.allowUnfreePredicate = pkg: elem (getName pkg) config.unfree.allowedNames;
      config.unfree.allowedNames = mkIf (gpu.vendor == "nVidia Corporation") [
        "nvidia-x11"
        "nvidia-settings"
      ];
    };

  flake.darwinModules.unfree = {
    config.nixpkgs.config.allowUnfree = true; # Only blanket allow is possible on nix-darwin.
  };
}
