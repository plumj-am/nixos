{ self }:
let
  inherit (self.attrsets) attrNames isAttrs;
  inherit (self.lists) genList isList;
  inherit (self.trivial) isBool isFloat isInt;
  inherit (self.strings)
    replaceStrings
    concatStringsSep
    isString
    typeOf
    ;
  inherit (self.generators) keyValue mkKeyValueDefault;

in
{
  generators = {
    keyValueEqualsSep = keyValue {
      listsAsDuplicateKeys = true;
      mkKeyValue = mkKeyValueDefault { } " = ";
    };

    keyValueSpaceSep = keyValue {
      listsAsDuplicateKeys = true;
      mkKeyValue = mkKeyValueDefault { } " ";
    };

    # Helper for ZON enum literals.
    # Usage: zon.enum "vertical"  →  produces .vertical in output
    zon.enum = name: {
      _type = "zon-enum";
      inherit name;
    };

    # ZON (Zig Object Notation) generator.
    # Converts Nix values to ZON text suitable for Zig config files.
    #   - attrsets -> struct: .{ .key = val, … }
    #   - lists    -> array:  .{ elem, … }
    #   - strings  -> "quoted" with escaping
    #   - numbers  -> literal
    #   - bools    -> true / false
    #   - zon.enum -> .identifier (see above)
    #
    # I hate this garbage so much I'd rather write a generator than write
    # the damn config.
    #
    # See a usage example in ./zyouz.nix.
    toZON =
      value:
      let
        esc = replaceStrings [ "\\" "\"" "\n" "\r" "\t" ] [ "\\\\" "\\\"" "\\n" "\\r" "\\t" ];
        escapeStr = s: "\"${esc s}\"";
        indent = n: concatStringsSep "" <| genList (_: "  ") n;

        go =
          level: v:
          if isString v then
            escapeStr v
          else if isInt v then
            toString v
          else if isFloat v then
            toString v
          else if isBool v then
            if v then "true" else "false"
          else if isList v then
            if v == [ ] then
              ".{}"
            else
              let
                items = map (go <| level + 1) v;
                inner = concatStringsSep ",\n" <| map (s: "${indent <| level + 1}${s}") items;
              in
              ".{\n${inner},\n${indent level}}"
          else if isAttrs v then
            if v ? _type && v._type == "zon-enum" then
              ".${v.name}"
            else
              let
                names = attrNames <| removeAttrs v [ "_type" ];
                fields = map (name: ".${name} = ${go (level + 1) v.${name}}") names;
              in
              if fields == [ ] then
                ".{}"
              else
                let
                  inner = concatStringsSep ",\n" <| map (s: "${indent <| level + 1}${s}") fields;
                in
                ".{\n${inner},\n${indent level}}"
          else
            throw "toZON: unsupported type ${typeOf v}";
      in
      go 0 value;
  };
}
