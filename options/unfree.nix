{ self, ... }:
{
  flake.nixosModules.unfree = self.nixosModules.unfree-options;
  flake.nixosModules.unfree-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) listOf str;
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
    };
}
