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

      security.rtkit.enable = true;

      # Disables built-in audio. Only use NVIDIA audio output.
      # boot.extraModprobeConfig = ''
      #   options snd_hda_intel enable=0,1
      # '';
    };
}
