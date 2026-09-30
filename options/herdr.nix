{ self, ... }:
{
  flake.modules.common.herdr = self.modules.common.herdr-options;
  flake.modules.common.herdr-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types)
        enum
        listOf
        nullOr
        str
        submodule
        ;
    in
    {
      options.herdr.keys.command = mkOption {
        type =
          listOf
          <| submodule {
            options = {
              key = lib.mkOption {
                type = str;
              };
              type = mkOption {
                type =
                  nullOr
                  <| enum [
                    "popup"
                    "pane"
                    "shell"
                  ];
                default = "pane";
              };
              width = mkOption {
                type = nullOr str;
                default = null;
              };
              height = mkOption {
                type = nullOr str;
                default = null;
              };
              command = mkOption {
                type = nullOr str;
                default = null;
              };
              description = mkOption {
                type = nullOr str;
                default = null;
              };
            };
          };
        default = [ ];
      };
    };
}
