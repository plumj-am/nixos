{ self, ... }:
{
  flake.modules.common.entities = self.modules.common.entities-options;
  flake.modules.common.entities-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) anything attrsOf;
    in
    {
      options.flake.entities = mkOption {
        type = attrsOf anything;
        default = { };
        description = ''
          All persistent entities associated with this configuration collection.
        '';
      };
    };
}
