{ self }:
let
  inherit (self.options) mkOption;
  inherit (self.types) nullOr;

  mkOptionOfType = type: rest: mkOption ({ inherit type; } // rest);
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

    # Functions below are made to shorten option declarations. They are
    # flexible and optionally accept a second "rest" parameter that is
    # applied _before_ the function applies it's attributes.

    # Make an option with `default = null;` and `type = nullOr <type>;`
    # where `<type>` is a positional argument.
    #
    # `rest` is passed through to `mkOptionOfType`.
    #
    # Usage:
    # ```
    # # Simple version without "rest".
    # options.user.name = mkOptionOrNull str;
    #
    # # With "rest".
    # options.user.name = mkOptionOrNull str {
    #   description = "user name";
    # };
    # ```
    mkOptionNullOr =
      type:
      let
        mk = rest: mkOptionOfType (nullOr type) ({ default = null; } // rest);
      in
      mk { } // { __functor = _: mk; };

    # Make an option with `type = <type>;` where `<type>` is a positional
    # argument.
    #
    # `rest` is passed through to `mkOptionOfType`.
    #
    # Usage:
    # ```
    # # Simple version without "rest".
    # options.shell.aliases = mkOptionOf (listOf str);
    #
    # # With complex type and "rest".
    # options.services.rustic.backups =
    #   mkOptionOf
    #     (
    #       attrsOf
    #       <| submodule {
    #         options = {
    #           /* ... */
    #         };
    #       }
    #     )
    #     {
    #       description = "";
    #       default = { };
    #     };
    # ```
    mkOptionOf =
      type:
      let
        mk = mkOptionOfType type;
      in
      mk { } // { __functor = _: mk; };
  };
}
