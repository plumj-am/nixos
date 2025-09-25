{ config, lib, pkgs, ... }: let
  inherit (lib) enabled mkIf;
in mkIf config.isDesktop {
  services.pipewire = enabled {
    audio.enable = true;
    pulse.enable = true;
    jack.enable  = true;
    alsa         = enabled {
      support32Bit = true;
    };
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    helvum               # PipeWire patchbay GUI.
    pwvucontrol          # PipeWire volume control.
    pulsemixer           # Terminal-based audio mixer.
  ];
}
