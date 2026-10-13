{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.audio;
  flake.modules.nixos.audio =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton pkgs.pwvucontrol; # PipeWire volume control.

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
