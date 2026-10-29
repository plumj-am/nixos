{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.systemd-oomd;
  flake.modules.nixos.systemd-oomd = {
    systemd.oomd = {
      enable = true;
      enableSystemSlice = true;
      enableUserSlices = true;

      settings.OOM = {
        # Act before swap is exhausted.
        SwapUsedLimit = "80%";
        # PSI fallback for cgroups with no limit of their own; pressure, not usage.
        DefaultMemoryPressureLimit = "80%";
        # Kill only after avg10 pressure stays above the limit this long.
        DefaultMemoryPressureDurationSec = "20s";
      };
    };

    # Swap kills ignore ManagedOOMPreference for non-root cgroups, so they
    # cannot spare the user session. Sacrifice builds and services instead.
    systemd.slices = {
      "system".sliceConfig.ManagedOOMSwap = "kill";

      # Reclaim protection, not a reservation: costs nothing while memory is
      # uncontended, and keeps builds from evicting the interactive session's
      # pages when they are not.
      "user".sliceConfig.MemoryLow = "25%";

      # nix-daemon.slice nests under nix.slice. Nix's per-build cgroups carry no
      # memory accounting, so a pressure kill here takes the daemon and every
      # running build.
      "nix".sliceConfig = {
        ManagedOOMSwap = "kill";
        ManagedOOMMemoryPressure = "kill";
        ManagedOOMMemoryPressureLimit = "80%";
      };
    };

    # ManagedOOMPreference is not recursive, so target niri itself.
    systemd.user.units."niri.service" = {
      text = ''
        [Service]
        ManagedOOMPreference=omit
      '';
      overrideStrategy = "asDropin";
    };

    systemd.services."nix-daemon".serviceConfig = {
      Slice = "nix-daemon.slice";
      MemoryAccounting = true;
      # Throttle builds at 80% of RAM, leaving 20% for the desktop.
      MemoryHigh = "80%";
      # Kernel OOM killer prefers the daemon and its builds.
      OOMScoreAdjust = 1000;
    };
  };
}
