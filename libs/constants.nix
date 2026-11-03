# deadnix: skip
{ self, ... }:
{
  constants = {
    tailnet = "taild29fec.ts.net";

    # Hosts that serve `evix worker` over the tailnet, and how many parallel
    # connections the master opens to each. Kept here because the client shim
    # is a package and cannot read a host's NixOS module.
    #
    # One connection per host: each worker is a fresh Nix evaluator that loads
    # the flake's inputs before the handshake completes, and evix's setup
    # deadline is 30 seconds. Two per host miss it on a cold cache.
    evix = {
      port = 7357;
      remotes = [
        {
          host = "sloe";
          workers = 1;
        }
        {
          host = "plum";
          workers = 1;
        }
        {
          host = "date";
          workers = 1;
        }
      ];
    };

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
}
