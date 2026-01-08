{
  config.flake.modules.nixosModules.unfree =
    { config, lib, ... }:
    let
      inherit (lib.lists) elem;
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
    in
    {
      options.unfree.allowedPackageNames = mkOption {
        type = listOf str;
        default = [ ];
        description = "List of unfree package names to allow";
        example = [
          "discord"
          "vscode"
        ];
      };

      config.nixpkgs.config.allowUnfreePredicate =
        pkg: elem (lib.getName pkg) config.unfree.allowedPackageNames;
    };

  config.flake.modules.darwinModules.unfree =
    { config, lib, ... }:
    let
      inherit (lib.lists) elem;
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
    in
    {
      options.unfree.allowedPackageNames = mkOption {
        type = listOf str;
        default = [ ];
        description = "List of unfree package names to allow";
        example = [
          "discord"
          "vscode"
        ];
      };

      config.nixpkgs.config.allowUnfreePredicate =
        pkg: elem (lib.getName pkg) config.unfree.allowedPackageNames;
    };
}
