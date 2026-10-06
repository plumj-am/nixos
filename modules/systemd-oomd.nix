{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.systemd-oomd;
  flake.modules.nixos.systemd-oomd = {
    systemd.oomd = {
      enable = true;
      enableSystemSlice = true;
      enableUserSlices = true;

      settings.OOM = {
        SwapUsedLimit = "90%";
        DefaultMemoryPressureLimit = "60%";
        # Two 10s PSI windows of sustained pressure before a kill.
        DefaultMemoryPressureDurationSec = "20s";
      };
    };

    systemd.slices."system".sliceConfig.ManagedOOMSwap = "kill";
    systemd.slices."user".sliceConfig.ManagedOOMSwap = "kill";

    # nix-daemon.slice sits under nix.slice, so system.slice and
    # user.slice monitoring never reach it.
    systemd.slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "50%";
      ManagedOOMSwap = "kill";
    };

    # Never kill the user session.
    systemd.user.units."session.slice" = {
      text = ''
        [Slice]
        ManagedOOMPreference=omit
      '';
      overrideStrategy = "asDropin";
    };

    systemd.services."nix-daemon".serviceConfig = {
      Slice = "nix-daemon.slice";
      MemoryAccounting = true;
      # Begin throttling memory usage.
      MemoryHigh = "75%";
      # Prefer killing nix-daemon child processes if OOM does occur.
      OOMScoreAdjust = 1000;
    };
  };
}
