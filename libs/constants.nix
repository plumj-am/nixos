# deadnix: skip
{ self, ... }:
{
  constants = {
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
