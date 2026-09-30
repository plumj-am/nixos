{ self, ... }:
{
  flake.modules.common.entities = self.modules.common.entities-options;
  flake.modules.common.entities-options =
    { lib, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) anything attrsOf;
    in
    {
      options.flake.entities = mkOptionOf (attrsOf anything) {
        default = { };
        description = ''
          All persistent entities associated with this configuration collection.
        '';
      };
    };
}
