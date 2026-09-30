{ self, ... }:
{
  flake.modules.common.theme = self.modules.common.theme-options;
  flake.modules.common.theme-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) anything attrsOf enum;
    in
    {
      options.theme = mkOptionOf (attrsOf anything) {
        default = { };
        description = "Derived global theme configuration. Set `themeMode` instead.";
      };

      options.themeMode =
        mkOptionOf
          (enum [
            "dark"
            "light"
          ])
          {
            default = "light";
            description = "Active light or dark variant. Override per host with `themeMode`.";
          };
    };
}
