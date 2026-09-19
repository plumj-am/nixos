{ self, ... }:
{
  # TODO: remove after Rustic moved to ../services
  flake.modules.common.default = self.modules.common.impure-lib;
  flake.modules.common.impure-lib =
    {
      lib,
      ...
    }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) anything attrsOf;
    in
    {
      options.impureLib = mkOption {
        type = attrsOf anything;
        default = { };
        description = "Custom, lib library functions";
      };
    };
}
