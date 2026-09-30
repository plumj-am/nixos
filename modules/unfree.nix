{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.unfree;
  flake.modules.nixos.unfree =
    { lib, config, ... }:
    let
      inherit (lib.lists) elem;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkOptionOf;
      inherit (lib.strings) getName;
      inherit (lib.types) listOf str;

      inherit (config.systemInfo) gpu;
    in
    {
      options.unfree.allowedNames = mkOptionOf (listOf str) {
        default = [ ];
        description = "List of unfree package names to allow";
        example = [
          "discord"
          "vscode"
        ];
      };

      config.nixpkgs.config.allowUnfreePredicate = pkg: elem (getName pkg) config.unfree.allowedNames;

      config.unfree.allowedNames = mkIf (gpu.vendor == "nVidia Corporation") [
        "nvidia-x11"
        "nvidia-settings"
      ];
    };

  flake.modules.unfree.default = self.modules.unfree.unfree;
  flake.modules.darwin.unfree = {
    config.nixpkgs.config.allowUnfree = true; # Only blanket allow is possible on nix-darwin.
  };
}
