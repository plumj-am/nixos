{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktop {
  services.pipewire = enabled {
    audio = enabled;
    pulse = enabled;
    jack  = enabled;
    alsa  = enabled {
      support32Bit = true;
    };
  };

  security.rtkit.enable = true;

  # Disable built-in audio. Only use NVIDIA audio output.
  boot.extraModprobeConfig = ''
    options snd_hda_intel enable=0,1
  '';

  environment.systemPackages = [
    pkgs.helvum               # PipeWire patchbay GUI.
    pkgs.pwvucontrol          # PipeWire volume control.
    pkgs.pulsemixer           # Terminal-based audio mixer.
  ];
}
