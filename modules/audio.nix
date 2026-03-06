{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      services.pipewire = {
        enable = true;
        audio.enable = true;
        pulse.enable = true;
        jack.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };

      security.rtkit.enable = true;

      # Disable built-in audio. Only use NVIDIA audio output.
      boot.extraModprobeConfig = ''
        options snd_hda_intel enable=0,1
      '';

      environment.systemPackages = [
        pkgs.crosspipe # PipeWire patchbay GUI. <- `pkgs.helvum` removed - unmaintained and vulnerable, nix recommends crosspipe.
        pkgs.pwvucontrol # PipeWire volume control.
        pkgs.pulsemixer # Terminal-based audio mixer.
      ];
    };
}
