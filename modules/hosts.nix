{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
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

  # Yuzu | desktop | x86_64-linux | NixOS
  flake.nixosConfigurations.yuzu = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      ai
      ai-extra
      app-launcher
      ashell
      audio
      boot-systemd
      desktop-gui
      desktop-tools
      discord-gui
      discord-tui
      disks-normal
      disks-extra-swap
      disks-extra-zram-swap
      games
      gammastep
      graphics
      hardware-desktop
      helix-extra
      hyprlock
      jujutsu-extra
      kitty
      linux-kernel-zen
      mprocs
      niri
      notifications
      nix-settings-extra-desktop
      object-storage
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      power-menu
      process-management
      quickshell
      rust-desktop
      rss-tui
      sudo-extra-desktop
      theme-extra-fonts
      theme-extra-scripts
      yazi
      zellij
      {
        config = mkConfig inputs "yuzu" "x86_64-linux" "desktop" {
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";

          age.secrets = {
            nixStoreKey.rekeyFile = ../secrets/yuzu-nix-store-key.age;
            rssApiPassword = {
              rekeyFile = ../secrets/plum-rss-api-password.age;
              owner = "jam";
            };
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  # Date | laptop/server | x86_64-linux | NixOS
  flake.nixosConfigurations.date = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      ai
      ai-extra
      app-launcher
      ashell
      audio
      boot-systemd
      desktop-gui
      desktop-tools
      discord-gui
      discord-tui
      disks-normal
      disks-extra-swap
      disks-extra-zram-swap
      forgejo-action-runner
      games
      gammastep
      graphics
      hardware-desktop
      helix-extra
      hyprlock
      jujutsu-extra
      kitty
      linux-kernel-zen
      mprocs
      niri
      notifications
      nix-settings-extra-desktop
      nix-distributed-builder
      nix-distributed-builds
      object-storage
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      power-menu
      process-management
      quickshell
      rust-desktop
      rss-tui
      sudo-extra-desktop
      theme-extra-fonts
      theme-extra-scripts
      yazi
      zellij
      {
        config = mkConfig inputs "date" "x86_64-linux" "desktop" {
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfoVKZDyiyyMiX1JRFaaTELspG25MlLNq0kI2AANTa root@date";

          forgejo-action-runner = {
            strong = true;
          };

          age.secrets = {
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            nixStoreKey.rekeyFile = ../secrets/date-nix-store-key.age;
            rssApiPassword = {
              rekeyFile = ../secrets/plum-rss-api-password.age;
              owner = "jam";
            };
          };

          # Used as a server when not used as a laptop.
          services.logind.settings.Login = {
            HandleLidSwitch = "ignore";
            HandleLidSwitchDocked = "ignore";
            HandleLidSwitchExternalPower = "ignore";
            IdleAction = "ignore";
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  # Pear | WSL | x86_64-linux | NixOS-WSL
  flake.nixosConfigurations.pear = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      desktop-tools
      jujutsu-extra
      linux-kernel-zen
      nix-distributed-builds
      nix-distributed-builder
      # object-storage
      sudo-extra-desktop
      wsl
      {
        config = mkConfig inputs "pear" "x86_64-linux" "wsl" {
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ root@pear";

          age.secrets = {
            # TODO
            # nixStoreKey.rekeyFile = ../secrets/yuzu-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  # Plum | server | x86_64-linux | NixOS
  flake.nixosConfigurations.plum = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      acme
      boot-grub
      cgit
      disks-disko
      forgejo
      freshrss-server
      forgejo-action-runner
      goatcounter
      linux-kernel-latest
      nginx
      nix-distributed-builds
      nix-distributed-builder
      nix-settings-extra-server
      object-storage
      opengist
      prometheus-node-exporter
      rust
      sudo-extra-server
      uptime-kuma
      website-personal
      { hardware.facter.reportPath = ./facter/plum.json; }
      {
        config = mkConfig inputs "plum" "x86_64-linux" "server" {
          networking = {
            domain = "plumj.am";
            firewall.allowedTCPPorts = [
              22
              80
              443
            ];
          };

          forgejo-action-runner = {
            strong = true;
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";

          age.secrets = {
            forgejoSigningKey = {
              rekeyFile = ../secrets/plum-forgejo-signing-key.age;
              owner = "forgejo";
            };
            forgejoSigningKeyPub = {
              rekeyFile = ../secrets/plum-forgejo-signing-key-pub.age;
              owner = "forgejo";
            };
            opengistEnvironment = {
              rekeyFile = ../secrets/plum-opengist-environment.age;
              owner = "forgejo";
            };
            rssAdminPassword = {
              rekeyFile = ../secrets/plum-rss-password.age;
              owner = "freshrss";
              mode = "400";
            };
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            forgejoAdminPassword.rekeyFile = ../secrets/plum-forgejo-password.age;
            acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;
            nixStoreKey.rekeyFile = ../secrets/plum-nix-store-key.age;
            resticPassword.rekeyFile = ../secrets/plum-restic-password.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  # Kiwi | server | x86_64-linux | NixOS
  flake.nixosConfigurations.kiwi = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      acme
      boot-grub
      disks-disko
      forgejo-action-runner
      linux-kernel-latest
      nginx
      nix-distributed-builds
      nix-distributed-builder
      nix-settings-extra-server
      object-storage
      prometheus-node-exporter
      rust
      sudo-extra-server
      website-dr-radka
      {
        config = mkConfig inputs "kiwi" "x86_64-linux" "server" {
          networking = {
            domain = "dr-radka.pl";
            firewall.allowedTCPPorts = [
              22
              80
              443
            ];
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af root@kiwi";

          age.secrets = {
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;
            drRadkaEnvironment.rekeyFile = ../secrets/kiwi-dr-radka-environment.age;
            nixStoreKey.rekeyFile = ../secrets/kiwi-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  # Sloe | server | x86_64-linux | NixOS
  flake.nixosConfigurations.sloe = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      boot-grub
      disks-disko
      forgejo-action-runner
      linux-kernel-latest
      nix-distributed-builds
      nix-distributed-builder
      nix-settings-extra-server
      object-storage
      prometheus-node-exporter
      rust
      sudo-extra-server
      {
        config = mkConfig inputs "sloe" "x86_64-linux" "server" {

          forgejo-action-runner = {
            strong = true;
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK42xzC/vWHZC9SiU/8IBBd2pn7mggBYFQ8themKAic/ root@sloe";
          age.secrets = {
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            nixStoreKey.rekeyFile = ../secrets/sloe-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  # Blackwell | server | x86_64-linux | NixOS
  flake.nixosConfigurations.blackwell = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      boot-grub
      disks-disko
      forgejo-action-runner
      linux-kernel-latest
      nix-distributed-builds
      nix-distributed-builder
      nix-settings-extra-server
      object-storage
      prometheus-node-exporter
      rust
      sudo-extra-server
      {
        config = mkConfig inputs "blackwell" "x86_64-linux" "server" {

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSi4SKhqze7ZzhJFcUF9KW/4nXX1MfvZjUqrYWNDi9c root@blackwell";

          age.secrets = {
            forgejoRunnerToken.rekeyFile = ../secrets/plum-forgejo-runner-token.age;
            acmeEnvironment.rekeyFile = ../secrets/acme-environment.age;
            nixStoreKey.rekeyFile = ../secrets/blackwell-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };

  # Lime | Macbook | x86_64-linux | nix-darwin
  flake.darwinConfigurations.lime = inputs.os-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.darwin; [
      aspectsBase

      app-launcher
      nix-settings-extra-darwin
      rust-desktop
      {
        config = mkConfig inputs "lime" "aarch64-darwin" "desktop" {
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeG5tRLj+z0LlAhH60rQuvRarHWuYE+fYMEgPvGbMrW jam@lime";

          age.secrets = {
            id.rekeyFile = ../secrets/lime-id.age;
            s3AccessKey.rekeyFile = ../secrets/s3-access-key.age;
            s3SecretKey.rekeyFile = ../secrets/s3-secret-key.age;
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

          system.stateVersion = 6;
        };
      }
    ];
  };
}
