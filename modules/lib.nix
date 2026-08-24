{ self, ... }:
{
  flake.mkConfig =
    inputs: host: platform: rest:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (lib) mkMerge;
    in
    mkMerge [
      {
        nixpkgs.hostPlatform = platform;

        networking.hostName = host;

        sops.secrets.password = {
          sopsFile = ../secrets/${host}/password.yaml;
          neededForUsers = true;
        };

        sops.secrets.id = {
          sopsFile = ../secrets/${host}/id.yaml;
        };

        sops.secrets.nix-store-key = {
          sopsFile = ../secrets/all/nix-store-keys.yaml;
          key = host;
        };
      }
      rest
    ];

  flake.modules.common.default = self.modules.common.lib;
  flake.modules.common.lib =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (pkgs.formats) keyValue;
      inherit (lib.generators) mkKeyValueDefault;
      inherit (lib.strings) replaceStrings;
      inherit (lib.options) mkOption;
      inherit (lib.types) attrs;
      inherit (lib.modules) mkIf;
    in
    {
      options.myLib = lib.mkOption {
        type = attrs;
        default = { };
        description = "Custom library functions";
      };

      # NOTE: `myLib` needs `config` to exist first because it references config
      # in its functions.
      # It works here because the line below creates a lazy reference that
      # resolves after `config` is built.
      # FIXME: I will do this better at the flake level soon for pure items.
      config._module.args.lib' = config.myLib;

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

        # Create a .desktop file entry for app launchers.
        mkDesktopEntry =
          {
            name,
            exec,
            terminal ? false,
            icon ? "preferences-color-symbolic",
          }:
          (mkIf config.nixpkgs.hostPlatform.isLinux (
            pkgs.makeDesktopItem {
              inherit
                name
                exec
                terminal
                icon
                ;
              desktopName = replaceStrings [ "-" ] [ " " ] name;
            }
          ));

        systemdHardened = {
          RuntimeDirectoryMode = "0755";
          ProcSubset = "pid";
          ProtectProc = "invisible";
          UMask = "0027";
          CapabilityBoundingSet = "";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RemoveIPC = true;
          PrivateMounts = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "~@cpu-emulation @debug @keyring @mount @obsolete @privileged @setuid"
            "setrlimit"
          ];
        };

        # Helper for ZON enum literals.
        # Usage: zon.enum "vertical"  →  produces .vertical in output
        zon = {
          enum = name: {
            _type = "zon-enum";
            inherit name;
          };
        };

        generators = {
          keyValueEqualsSep = keyValue {
            listsAsDuplicateKeys = true;
            mkKeyValue = mkKeyValueDefault { } " = ";
          };

          keyValueSpaceSep = keyValue {
            listsAsDuplicateKeys = true;
            mkKeyValue = mkKeyValueDefault { } " ";
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
              inherit (lib.attrsets) attrNames isAttrs;
              inherit (lib.lists) genList isList;
              inherit (lib.trivial) isBool isFloat isInt;
              inherit (lib.strings)
                replaceStrings
                concatStringsSep
                isString
                typeOf
                ;

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
      };
    };
}
