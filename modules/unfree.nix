{
  flake.modules.nixos.unfree =
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

  flake.modules.darwin.unfree = {
    config.nixpkgs.config.allowUnfree = true; # Only blanket allow is possible on nix-darwin.
  };
}
