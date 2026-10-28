{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.audio;
  flake.modules.nixos.audio =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = [
        pkgs.pwvucontrol # PipeWire volume control.

        # pw-play is a symlink; shadow it with a wrapper that pins the stream
        # volume to 1%. Caller flags still win because pw-cat keeps the last
        # `--volume`.
        #
        # Why is this so loud by default lol.
        (
          lib.hiPrio
          <| pkgs.writeShellScriptBin "pw-play" ''
            exec ${config.services.pipewire.package}/bin/pw-play --volume=0.01 "$@"
          ''
        )
      ];

      services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };

      # AX211 (8087:0033) drops A2DP completion reports when USB autosuspend
      # fires mid-stream -> choppy. Journal today: 10 "Failure in Bluetooth
      # audio transport" plus "Missing completion reports ... firmware bug?".
      boot.extraModprobeConfig = ''
        options btusb enable_autosuspend=N
      '';

      # rfcomm required for HFP/PBAP/AVRCP; not autoloaded -> "Protocol not
      # supported (93)" in bluetoothd. AAC needs no config: SPA loads
      # `libspa-codec-bluez5-aac.so` and negotiates the best mutually-advertised
      # codec automatically.
      boot.kernelModules = singleton "rfcomm";

      security.rtkit.enable = true;
    };
}
