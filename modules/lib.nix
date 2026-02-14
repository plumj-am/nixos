# Custom library functions and such.
let
  commonModule =
    { lib, config, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (config.age) secrets;
      inherit (config.networking) hostName;
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

        # Create a .desktop file entry for app launchers.
        mkDesktopEntry =
          { pkgs }:
          {
            name,
            exec,
            terminal ? false,
            icon ? "preferences-color-symbolic",
          }:
          pkgs.writeTextFile {
            inherit name;
            destination = "/share/applications/${name}.desktop";
            text = # ini
              ''
                [Desktop Entry]
                Name=${lib.strings.replaceStrings [ "-" ] [ " " ] name}
                Icon=${icon}
                Exec=${exec}
                Terminal=${if terminal then "true" else "false"}
              '';
          };

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
      };
    };

in
{
  flake.mkConfig =
    inputs: host: platform: type: rest:
    let
      lib = inputs.os.lib;
      inherit (lib) mkMerge;
      inherit (lib.strings) hasSuffix;
      inherit (lib.attrsets) optionalAttrs;

      isLinux = hasSuffix "linux" platform;
    in
    mkMerge [
      {
        inherit type;

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
          zaiKey = {
            rekeyFile = ../secrets/z-ai-key.age;
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
