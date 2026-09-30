{
  flake.services.tarssh =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.lists) optional singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options)
        mkEnableOption
        mkOptionNullOr
        mkOptionOf
        mkPackageOption
        ;
      inherit (lib.strings) concatStringsSep replicate;
      inherit (lib.types)
        bool
        int
        port
        str
        ;
      inherit (lib.types) addCheck;

      cfg = config.services.tarssh;

      listenArg = "${cfg.listenAddress}:${toString cfg.listenPort}";
      needsPrivileges = cfg.listenPort < 1024;
      dynamicUser = cfg.user == null && cfg.group == null;
      capabilities = optional needsPrivileges "CAP_NET_BIND_SERVICE";
    in
    {
      options.services.tarssh = {
        enable = mkEnableOption "tarssh, an SSH tarpit server";

        package = mkPackageOption pkgs "tarssh" { };

        listenAddress = mkOptionOf (addCheck str (s: !(lib.hasInfix ":" s))) {
          default = "0.0.0.0";
          example = "[::]";
          description = ''
            Host to bind to. Must not include a port; use `listenPort`.
            Tarssh accepts `[::]` for dual-stack and bare IPv6 hosts.
          '';
        };

        listenPort = mkOptionOf port {
          default = 2222;
          description = ''
            TCP port to bind. Setting this below 1024 grants the unit
            `CAP_NET_BIND_SERVICE` automatically.
          '';
        };

        delay = mkOptionOf int {
          default = 10;
          description = "Seconds between responses (`--delay`).";
        };

        timeout = mkOptionOf int {
          default = 30;
          description = "Socket write timeout in seconds (`--timeout`).";
        };

        maxClients = mkOptionOf int {
          default = 4096;
          description = "Best-effort connection limit (`--max-clients`).";
        };

        user = mkOptionNullOr str {
          description = ''
            Run as this user (`--user`). When set, tarssh also adopts the
            user's primary group; prefer setting `group` explicitly if the
            primary group is not desired.
          '';
        };

        group = mkOptionNullOr str {
          description = "Run as this group (`--group`).";
        };

        chroot = mkOptionNullOr str {
          description = "Chroot to this directory before serving (`--chroot`).";
        };

        verbose = mkOptionOf int {
          default = 0;
          description = ''
            Verbosity level. Each unit adds one `-v` flag to tarssh's
            command line, so `2` produces `-v -v` and `3` produces
            `-v -v -v`.
          '';
        };

        disableLogIdent = mkOptionOf bool {
          default = false;
          description = "Strip the `tarssh` module name from log lines (`--disable-log-ident`).";
        };

        disableLogLevel = mkOptionOf bool {
          default = false;
          description = "Strip the log level prefix (`--disable-log-level`).";
        };

        disableLogTimestamps = mkOptionOf bool {
          default = false;
          description = "Strip timestamps from log lines (`--disable-log-timestamps`).";
        };

        openFirewall = mkOptionOf bool {
          default = false;
          description = "Whether to open `listenPort` in the firewall.";
        };
      };

      config = mkIf cfg.enable {
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
          wantedBy = singleton "multi-user.target";
          after = singleton "network.target";
          serviceConfig =
            let
              userAttrs =
                optionalAttrs (cfg.user != null) { User = cfg.user; }
                // optionalAttrs (cfg.group != null) { Group = cfg.group; };
              verboseFlag = if cfg.verbose > 0 then concatStringsSep " " (replicate cfg.verbose "-v") else "";
            in
            {
              ExecStart = concatStringsSep " " (
                [ (getExe cfg.package) ]
                ++ [ "--listen ${listenArg}" ]
                ++ [ "--delay ${toString cfg.delay}" ]
                ++ [ "--timeout ${toString cfg.timeout}" ]
                ++ [ "--max-clients ${toString cfg.maxClients}" ]
                ++ optional (cfg.user != null) "--user ${cfg.user}"
                ++ optional (cfg.group != null) "--group ${cfg.group}"
                ++ optional (cfg.chroot != null) "--chroot ${cfg.chroot}"
                ++ optional cfg.disableLogIdent "--disable-log-ident"
                ++ optional cfg.disableLogLevel "--disable-log-level"
                ++ optional cfg.disableLogTimestamps "--disable-log-timestamps"
                ++ optional (cfg.verbose > 0) verboseFlag
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

        networking.firewall.allowedTCPPorts = optional cfg.openFirewall cfg.listenPort;
      };
    };
}
