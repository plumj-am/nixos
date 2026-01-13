let
  commonModule =
    { config, lib, ... }:
    let
      inherit (lib.lists) elem;
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
      inherit (lib.strings) getName;
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
    };

in
{
  config.flake.modules.nixos.unfree = commonModule;
  config.flake.modules.darwin.unfree = commonModule;
}
