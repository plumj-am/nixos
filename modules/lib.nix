# Custom library functions and such.
let
  commonModule =
    { lib, ... }:
    let
      inherit (lib.options) mkOption;
    in
    {
      options.myLib = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Custom library functions";
      };

      config.myLib = {
        # Creates a mergeable attribute set that can be called as a function
        # allows syntax like: `config.myLib.merge { option1 = value1; } <| conditionalOptions`
        merge = lib.mkMerge [ ] // {
          __functor =
            self: next:
            self
            // {
              contents = self.contents ++ [ next ];
            };
        };

        mkConst =
          value:
          mkOption {
            default = value;
            readOnly = true;
          };

        mkValue =
          default:
          mkOption {
            inherit default;
          };
      };
    };

in
{
  config.flake.modules.nixos.lib = commonModule;
  config.flake.modules.darwin.lib = commonModule;
}
