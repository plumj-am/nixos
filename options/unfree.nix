{ self, ... }:
{
  flake.modules.nixos.unfree = self.modules.nixos.unfree-options;
  flake.modules.nixos.unfree-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) listOf str;
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
    };
}
