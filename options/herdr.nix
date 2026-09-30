{ self, ... }:
{
  flake.modules.common.herdr = self.modules.common.herdr-options;
  flake.modules.common.herdr-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionNullOr mkOptionOf;
      inherit (lib.types)
        enum
        listOf
        nullOr
        str
        submodule
        ;
    in
    {
      options.herdr.keys.command =
        mkOptionOf
          (
            listOf
            <| submodule {
              options = {
                key = mkOptionOf str;
                type =
                  mkOptionOf
                    (
                      nullOr
                      <| enum [
                        "popup"
                        "pane"
                        "shell"
                      ]
                    )
                    {
                      default = "pane";
                    };
                width = mkOptionNullOr str;
                height = mkOptionNullOr str;
                command = mkOptionNullOr str;
                description = mkOptionNullOr str;
              };
            }
          )
          {
            default = [ ];
          };
    };
}
