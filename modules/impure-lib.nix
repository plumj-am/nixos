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
      inherit (lib.types) attrsOf anything;
      inherit (lib.options) mkOption;
    in
    {
      options.impureLib = mkOption {
        type = attrsOf anything;
        default = { };
        description = "Custom, lib library functions";
      };
    };
}
