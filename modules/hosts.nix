{ inputs, ... }:
{
  flake.nixosConfigurations.yuzu = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    system = "x86_64-linux";

    modules = with inputs.self.modules.nixos; [
      audio
      boot
      desktop-gui
      desktop-tools
      disable-nano
      disks-desktop-swap
      disks-zram-swap
      dynamic-binaries
      games
      graphics
      hardware-desktop
      hjem
      jujutsu-extra
      keyboard
      keys
      locale
      linux-kernel-desktop
      mouse
      netrc
      network
      nix-settings
      openssh
      packages
      packages-extra-desktop
      power-menu
      process-management
      rebuild
      rust-desktop
      scratchpads
      secret-manager
      sudo-desktop
      system-types
      tailscale
      theme
      theme-fonts
      theme-scripts
      unfree
      users
      window-manager
      yubikey
      {
        config.operatingSystem = "linux";
        config.systemType = "desktop";

        config.network = {
          hostName = "yuzu";
          interfaces = [ "ts0" ];
          tcpPorts = [ 22 ];
        };

        config.unfree.allowedNames = [
          "nvidia-x11"
          "nvidia-settings"
          "steam"
          "steam-unwrapped"
        ];

        config.age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";

        config.age.secrets = {
          id.rekeyFile = ../secrets/yuzu-id.age;
          password.rekeyFile = ../secrets/yuzu-password.age;
          context7Key = {
            rekeyFile = ../secrets/context7-key.age;
            owner = "jam";
            mode = "400";
          };
          z-ai-key = {
            rekeyFile = ../secrets/z-ai-key.age;
            owner = "jam";
            mode = "400";
          };
        };

        config.openssh = {
          enable = true;
        };

        config.useTheme = true;

        config.system.stateVersion = "26.05";
      }
    ];
  };

  flake.darwinConfigurations.lime = inputs.os-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    system = "aarch64-darwin";

    modules = with inputs.self.modules.darwin; [
      app-launcher
      hjem
      keys
      network
      openssh
      packages
      rust-desktop
      secret-manager
      sudo
      system-types
      tailscale
      unfree
      users
      {
        config.operatingSystem = "darwin";
        config.systemType = "desktop";

        config.network.hostName = "lime";

        config.unfree.allowedNames = [
          "raycast"
        ];

        config.openssh.enable = true;

        config.system.stateVersion = 6;
      }
    ];
  };
}
