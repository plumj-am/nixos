{ self, ... }:
{
  flake.commonModules.theme = self.commonModules.theme-options;
  flake.commonModules.theme-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) anything attrsOf enum;
    in
    {
      options.theme = mkOption {
        type = attrsOf anything;
        default = { };
        description = "Derived global theme configuration. Set `themeMode` instead.";
      };

      options.themeMode = mkOption {
        type = enum [
          "dark"
          "light"
        ];
        default = "light";
        description = "Active light or dark variant. Override per host with `themeMode`.";
      };
    };
}
