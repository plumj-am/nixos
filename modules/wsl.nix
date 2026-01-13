{
  flake.modules.nixos.wsl =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
    in
    {
      imports = [
        inputs.os-wsl.nixosModules.default
      ];

      wsl = {
        enable = true;
        defaultUser = "jam";
        startMenuLaunchers = false; # Hide from start menu.
        useWindowsDriver = true; # Use Windows graphics drivers.
        docker-desktop.enable = true; # Allow docker-desktop to use NixOS-WSL.

        # Allow USB passthrough.
        usbip = {
          enable = true;
          # autoAttach = [ "1-9" ]; # Add device IDs like "4-1" to auto-attach USB devices.
        };

        # Necessary for usbip.
        extraBin = [
          { src = "${lib.getExe' pkgs.coreutils-full "ls"}"; }
          { src = "${lib.getExe pkgs.bash}"; }
          { src = "${lib.getExe' pkgs.linuxPackages.usbip "usbip"}"; }
        ];

        wslConf = {
          automount = {
            root = "/mnt";
            options = "metadata,uid=1000,gid=100,noatime";
          };

          boot.systemd = true;

          interop = {
            enabled = true;
            appendWindowsPath = false; # Do not add Windows executables to WSL path.
          };

          network.generateHosts = true;
        };
      };
    };
}
