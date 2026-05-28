# Custom library functions and such.
let
  commonModule =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (pkgs.formats) keyValue;
      inherit (lib.generators) mkKeyValueDefault;
      inherit (lib.trivial) readFile;
      inherit (lib.strings)
        splitString
        hasPrefix
        concatStringsSep
        match
        head
        filter
        replaceStrings
        ;
      inherit (lib.lists) optionals;
      inherit (lib.options) mkOption;
      inherit (lib.types) attrs;
      inherit (lib.modules) mkIf;
      inherit (config.age) secrets;
      inherit (config.networking) hostName;
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

        mkDirtyHaskellScript =
          name:
          {
            deps ? [ ],
            path,
            ghcArgs ? [ ],
          }:
          let
            source = readFile path;
            lines = splitString "\n" source;
            isShebang = line: hasPrefix "#!" line;
            filteredLines = filter (line: !(isShebang line)) lines;
            cleanSource = concatStringsSep "\n" filteredLines;
            moduleLines = filter (line: hasPrefix "module " line) filteredLines;
            moduleDecl = if moduleLines != [ ] then head moduleLines else null;
            matchResult = if moduleDecl != null then match "module ([^ ]+).*" moduleDecl else null;
            moduleName = if matchResult != null then head matchResult else null;
            mainIsArg = optionals (moduleName != null && moduleName != "Main") [
              "-main-is"
              "${moduleName}.main"
            ];
            bin = pkgs.writers.writeHaskell name {
              libraries = map (d: pkgs.haskellPackages.${d}) deps;
              ghcArgs = mainIsArg ++ ghcArgs;
            } cleanSource;
          in
          pkgs.runCommand name { } ''
            mkdir -p $out/bin
            cp ${bin} $out/bin/${name}
            chmod +x $out/bin/${name}
          '';

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

        # Backup creation helper with restic to keep constants consistent.
        # Can be used like so:
        # `services.restic.backups.<service> = mkResticBackup "<service>" { <rest> }`
        mkResticBackup =
          name: rest:
          {
            repository = "s3:https://fsn1.your-objectstorage.com/plumjam/backups/${hostName}/${name}";
            passwordFile = secrets.resticPassword.path;
            initialize = true;
            pruneOpts = [
              "--keep-daily 8"
              "--keep-weekly 5"
              "--keep-monthly 3"
            ];
          }
          // rest;

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

in
{
  flake.mkConfig =
    inputs: host: platform: rest:
    let
      lib = inputs.os.lib;
      inherit (lib) mkMerge;
      inherit (lib.strings) hasSuffix;
      inherit (lib.attrsets) optionalAttrs;

      isLinux = hasSuffix "linux" platform;
    in
    mkMerge [
      {
        nixpkgs.hostPlatform = platform;

        networking.hostName = host;

        age.secrets = {
          id.rekeyFile = ../secrets/${host}-id.age;
          s3AccessKey.rekeyFile = ../secrets/s3-access-key.age;
          s3SecretKey.rekeyFile = ../secrets/s3-secret-key.age;
          context7Key = {
            rekeyFile = ../secrets/context7-key.age;
            owner = "jam";
            mode = "400";
          };
        }
        // optionalAttrs isLinux {
          password.rekeyFile = ../secrets/${host}-password.age;
        };
      }
      (optionalAttrs isLinux {
        unfree.allowedNames = [
          "nvidia-x11"
          "nvidia-settings"
          "steam"
          "steam-unwrapped"
        ];
      })
      rest
    ];

  flake.modules.nixos.lib = commonModule;
  flake.modules.darwin.lib = commonModule;
}
