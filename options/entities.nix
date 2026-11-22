{ self, ... }:
{
  flake.commonModules.entities = self.commonModules.entities-options;
  flake.commonModules.entities-options =
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
