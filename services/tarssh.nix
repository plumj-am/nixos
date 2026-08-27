{
  flake.services.tarssh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.meta) getExe;
      inherit (lib.lists) optionals;
      inherit (lib.types)
        nullOr
        str
        int
        bool
        port
        ;
      inherit (lib.types) addCheck;

      cfg = config.services.tarssh;

      listenArg = "${cfg.listenAddress}:${toString cfg.listenPort}";
      needsPrivileges = cfg.listenPort < 1024;
      dynamicUser = cfg.user == null && cfg.group == null;
      capabilities = optionals needsPrivileges [ "CAP_NET_BIND_SERVICE" ];
    in
    {
      options.services.tarssh = {
        enable = mkEnableOption "tarssh, an SSH tarpit server";

        package = mkPackageOption pkgs "tarssh" { };

        listenAddress = mkOption {
          type = addCheck str (s: !(lib.hasInfix ":" s));
          default = "0.0.0.0";
          example = "[::]";
          description = ''
            Host to bind to. Must not include a port; use `listenPort`.
            Tarssh accepts `[::]` for dual-stack and bare IPv6 hosts.
          '';
        };

        listenPort = mkOption {
          type = port;
          default = 2222;
          description = ''
            TCP port to bind. Setting this below 1024 grants the unit
            `CAP_NET_BIND_SERVICE` automatically.
          '';
        };

        delay = mkOption {
          type = int;
          default = 10;
          description = "Seconds between responses (`--delay`).";
        };

        timeout = mkOption {
          type = int;
          default = 30;
          description = "Socket write timeout in seconds (`--timeout`).";
        };

        maxClients = mkOption {
          type = int;
          default = 4096;
          description = "Best-effort connection limit (`--max-clients`).";
        };

        user = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Run as this user (`--user`). When set, tarssh also adopts the
            user's primary group; prefer setting `group` explicitly if the
            primary group is not desired.
          '';
        };

        group = mkOption {
          type = nullOr str;
          default = null;
          description = "Run as this group (`--group`).";
        };

        chroot = mkOption {
          type = nullOr str;
          default = null;
          description = "Chroot to this directory before serving (`--chroot`).";
        };

        verbose = mkOption {
          type = int;
          default = 0;
          description = ''
            Verbosity level. Each unit adds one `-v` flag to tarssh's
            command line, so `2` produces `-v -v` and `3` produces
            `-v -v -v`.
          '';
        };

        disableLogIdent = mkOption {
          type = bool;
          default = false;
          description = "Strip the `tarssh` module name from log lines (`--disable-log-ident`).";
        };

        disableLogLevel = mkOption {
          type = bool;
          default = false;
          description = "Strip the log level prefix (`--disable-log-level`).";
        };

        disableLogTimestamps = mkOption {
          type = bool;
          default = false;
          description = "Strip timestamps from log lines (`--disable-log-timestamps`).";
        };

        openFirewall = mkOption {
          type = bool;
          default = false;
          description = "Whether to open `listenPort` in the firewall.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = !(cfg.user != null && cfg.user == "root");
            message = ''
              services.tarssh: setting `user` to `root` is almost certainly
              wrong. Leave `user` as `null` (DynamicUser) or pick a dedicated
              unprivileged user.
            '';
          }
          {
            assertion = !(dynamicUser && cfg.chroot != null);
            message = ''
              services.tarssh: `chroot` cannot be combined with the default
              DynamicUser setup. systemd's DynamicUser allocates a transient
              uid that does not own the chroot directory, and tarssh will
              fail at startup. Either set `user` to a real account that owns
              `chroot`, or drop `chroot`.
            '';
          }
        ];

        systemd.services.tarssh = {
          description = "SSH tarpit (tarssh)";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig =
            let
              userAttrs =
                lib.optionalAttrs (cfg.user != null) { User = cfg.user; }
                // lib.optionalAttrs (cfg.group != null) { Group = cfg.group; };
              verboseFlag =
                if cfg.verbose > 0 then lib.strings.concatStringsSep " " (lib.replicate cfg.verbose "-v") else "";
            in
            {
              ExecStart = lib.concatStringsSep " " (
                [ (getExe cfg.package) ]
                ++ [ "--listen ${listenArg}" ]
                ++ [ "--delay ${toString cfg.delay}" ]
                ++ [ "--timeout ${toString cfg.timeout}" ]
                ++ [ "--max-clients ${toString cfg.maxClients}" ]
                ++ optionals (cfg.user != null) [ "--user ${cfg.user}" ]
                ++ optionals (cfg.group != null) [ "--group ${cfg.group}" ]
                ++ optionals (cfg.chroot != null) [ "--chroot ${cfg.chroot}" ]
                ++ optionals cfg.disableLogIdent [ "--disable-log-ident" ]
                ++ optionals cfg.disableLogLevel [ "--disable-log-level" ]
                ++ optionals cfg.disableLogTimestamps [ "--disable-log-timestamps" ]
                ++ optionals (cfg.verbose > 0) [ verboseFlag ]
              );

              DynamicUser = dynamicUser;
            }
            // userAttrs
            // {
              AmbientCapabilities = capabilities;
              CapabilityBoundingSet = capabilities;
              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateDevices = true;
              PrivateTmp = true;
              PrivateUsers = true;
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProcSubset = "pid";
              RemoveIPC = true;
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_INET6"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              SystemCallArchitectures = "native";
              SystemCallFilter = [
                "@system-service"
                "~@privileged"
                "~@resources"
              ];
              UMask = "0077";
            };
        };

        networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.listenPort;
      };
    };
}
