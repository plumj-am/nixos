{ inputs, ... }:
{
  flake-file.inputs = {
    os = {
      url = "github:NixOS/nixpkgs/nixos-unstable-small";
    };

    os-wsl = {
      url = "github:nix-community/NixOS-WSL/main";

      inputs.nixpkgs.follows = "os";
      inputs.flake-compat.follows = "";
    };

    os-darwin = {
      url = "github:nix-darwin/nix-darwin/master";

      inputs.nixpkgs.follows = "os";
    };
  };

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
      lib
      locale
      linux-kernel-zen
      mouse
      netrc
      network
      nix-settings
      openssh
      packages
      packages-extra-desktop
      power-menu
      process-management
      quickshell
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
          systemPlatform = "x86_64-linux";
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

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  flake.nixosConfigurations.plum = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    system = "x86_64-linux";
    modules = with inputs.self.modules.nixos; [
      acme
      boot-server
      disable-nano
      lib
      disks-server
      disks-zram-swap
      dynamic-binaries
      forgejo
      forgejo-action-runner
      goatcounter
      hjem
      keys
      locale
      linux-kernel
      netrc
      network
      nginx
      nix-cache
      nix-distributed-builds
      nix-distributed-builder
      nix-settings
      prometheus-node-exporter
      openssh
      packages
      rebuild
      rust
      secret-manager
      sudo-server
      system-types
      tailscale
      theme
      unfree
      uptime-kuma
      users
      virtualisation
      website-personal
      yubikey
      {
        config = {
          operatingSystem = "linux";
          systemPlatform = "x86_64-linux";
          systemType = "server";

          network = {
            hostName = "plum";
            domain = "plumj.am";
            tcpPorts = [
              22
              80
              443
            ];
          };

          cache = {
            fqdn = "cache1.plumj.am";
          };

          forgejo-action-runner = {
            labels = [
              "self-hosted:host"
              "plum:host"
              "docpad-infra:host"
            ];
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";

          age.secrets = {
            id.rekeyFile = ../secrets/plum-id.age;
            password.rekeyFile = ../secrets/plum-password.age;
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            forgejoAdminPassword.rekeyFile = ../secrets/plum-forgejo-password.age;
            nixServeKey.rekeyFile = ../secrets/plum-cache-key.age;
            acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;
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

        config.system.stateVersion = 6;
      }
    ];
  };
}
