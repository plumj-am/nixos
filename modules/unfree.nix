{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.unfree;
  flake.modules.nixos.unfree =
    { config, lib, ... }:
    let
      inherit (lib.lists) elem;
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
      inherit (lib.strings) getName;
      inherit (lib.modules) mkIf;

      inherit (config.systemInfo) gpu;
    in
    {
      options.unfree.allowedNames = mkOption {
        type = listOf str;
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
