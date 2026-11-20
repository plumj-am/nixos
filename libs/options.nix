{ self }:
let
  inherit (self.options) mkOption;
in
{
  options = {
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
}
