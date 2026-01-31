{
  flake.modules.nixos.graphics =
    { config, ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true; # Required for Steam and 32-bit applications.
      };

      # For Wayland.
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # Enable modesetting (required for Wayland).
        modesetting.enable = true;

        # For sleep handling.
        powerManagement.enable = true;

        powerManagement.finegrained = false;

        # Use open source kernel modules (recommended for RTX/GTX 16xx+).
        open = true;

        # Enable nvidia-settings menu.
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      # Environment variables for NVIDIA on Wayland.
      environment.sessionVariables = {
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";

        WLR_NO_HARDWARE_CURSORS = "1"; # Cursor fix.
      };

      boot.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
    };
}
