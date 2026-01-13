{ inputs, ... }:
{
  flake.nixosConfigurations.yuzu = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    system = "x86_64-linux";

    modules = with inputs.self.modules.nixos; [
      audio
      boot-desktop
      desktop-gui
      desktop-tools
      disable-nano
      disks-desktop-swap
      disks-zram-swap
      dynamic-binaries
      games
      gammastep
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
      virtualisation
      waybar
      window-manager
      yubikey
      {
        config = {
          operatingSystem = "linux";
          systemType = "desktop";

          network.hostName = "yuzu";

          unfree.allowedNames = [
            "nvidia-x11"
            "nvidia-settings"
            "steam"
            "steam-unwrapped"
          ];

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";

          age.secrets = {
            id.rekeyFile = ../secrets/yuzu-id.age;
            password.rekeyFile = ../secrets/yuzu-password.age;
            context7Key = {
              rekeyFile = ../secrets/context7-key.age;
              owner = "jam";
              mode = "400";
            };
            zaiKey = {
              rekeyFile = ../secrets/z-ai-key.age;
              owner = "jam";
              mode = "400";
            };
          };

          openssh.enable = true;

          useTheme = true;

          system.stateVersion = "26.05";
        };
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
