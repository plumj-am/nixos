{ inputs, ... }:
let
  inherit (inputs.os.lib) mkMerge;
  inherit (inputs.os.lib.attrsets) optionalAttrs;

  specialArgs = { inherit inputs; };

  commonModules = with inputs.self.modules.nixos; [
    disable-nano
    disable-nix-documentation
    dynamic-binaries
    hjem
    keys
    lib
    locale
    netrc
    network
    nix-settings
    openssh
    packages
    rebuild
    secret-manager
    system
    tailscale
    theme
    unfree
    users
    virtualisation
    yubikey
  ];

  desktopModules = with inputs.self.modules.nixos; [
    audio
    boot-systemd
    desktop-gui
    desktop-tools
    gammastep
    graphics
    hardware-desktop
    jujutsu-extra
    keyboard
    linux-kernel-zen
    mouse
    packages-extra-desktop
    power-menu
    process-management
    quickshell
    rust-desktop
    scratchpads
    sudo-desktop
    theme-extra-fonts
    theme-extra-scripts
    waybar
    window-manager
  ];

  serverModules = with inputs.self.modules.nixos; [
    forgejo-action-runner
    linux-kernel
    nix-distributed-builds
    nix-distributed-builder
    prometheus-node-exporter
    sudo-server
  ];

  mkConfig =
    host: platform: type: rest:
    mkMerge [
      {
        network.hostName = host;
        inherit type platform;

        age.secrets = {
          id.rekeyFile = ../secrets/${host}-id.age;
          password.rekeyFile = ../secrets/${host}-password.age;
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

        unfree.allowedNames = [
          "claude-code"
          "nvidia-x11"
          "nvidia-settings"
          "steam"
          "steam-unwrapped"
        ];
      }

      (optionalAttrs (type == "server") {
        forgejo-action-runner = {
          withDocker = true;
          labels = [
            "self-hosted:host"
            "${host}:host"
            "docpad-infra:host"
            "ubuntu-22.04:docker://docker.gitea.com/runner-images:ubuntu-22.04"
          ];
        };
      })
      rest
    ];
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

  flake.nixosConfigurations.yuzu = inputs.os.lib.nixosSystem {
    inherit specialArgs;

    modules =
      with inputs.self.modules.nixos;
      commonModules
      ++ desktopModules
      ++ [
        disks-normal
        disks-extra-swap
        disks-extra-zram-swap
        games
        object-storage
        {
          config = mkConfig "yuzu" "x86_64-linux" "desktop" {
            age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";

            age.secrets = {
              nixStoreKey.rekeyFile = ../secrets/yuzu-nix-store-key.age;
            };

            system.stateVersion = "26.05";
          };
        }
      ];
  };

  flake.nixosConfigurations.date = inputs.os.lib.nixosSystem {
    inherit specialArgs;

    modules =
      with inputs.self.modules.nixos;
      commonModules
      ++ desktopModules
      ++ [
        disks-normal
        disks-extra-swap
        disks-extra-zram-swap
        object-storage
        {
          config = mkConfig "date" "x86_64-linux" "desktop" {
            age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfoVKZDyiyyMiX1JRFaaTELspG25MlLNq0kI2AANTa root@date";

            age.secrets = {
              # TODO
              # nixStoreKey.rekeyFile = ../secrets/yuzu-nix-store-key.age;
            };

            system.stateVersion = "26.05";
          };
        }
      ];
  };

  flake.nixosConfigurations.pear = inputs.os.lib.nixosSystem {
    inherit specialArgs;

    modules =
      with inputs.self.modules.nixos;
      commonModules
      ++ [
        desktop-tools
        jujutsu-extra
        linux-kernel-zen
        object-storage
        packages-extra-desktop
        rust-desktop
        scratchpads
        sudo-desktop
        wsl
        {
          config = mkConfig "pear" "x86_64-linux" "wsl" {
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

  flake.nixosConfigurations.plum = inputs.os.lib.nixosSystem {
    inherit specialArgs;

    modules =
      with inputs.self.modules.nixos;
      commonModules
      ++ serverModules
      ++ [
        acme
        boot-grub
        disks-disko
        disks-extra-zram-swap
        forgejo
        goatcounter
        nginx
        object-storage
        rust
        uptime-kuma
        website-personal
        { hardware.facter.reportPath = ./facter/plum.json; }
        {
          config = mkConfig "plum" "x86_64-linux" "server" {
            network = {
              domain = "plumj.am";
              tcpPorts = [
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

  flake.nixosConfigurations.kiwi = inputs.os.lib.nixosSystem {
    inherit specialArgs;

    modules =
      with inputs.self.modules.nixos;
      commonModules
      ++ serverModules
      ++ [
        acme
        boot-grub
        disks-disko
        disks-extra-zram-swap
        nginx
        object-storage
        rust
        website-dr-radka
        {
          config = mkConfig "kiwi" "x86_64-linux" "server" {
            network = {
              domain = "dr-radka.pl";
              tcpPorts = [
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

  flake.nixosConfigurations.sloe = inputs.os.lib.nixosSystem {
    inherit specialArgs;

    modules =
      with inputs.self.modules.nixos;
      commonModules
      ++ serverModules
      ++ [
        boot-grub
        disks-disko
        disks-extra-zram-swap
        object-storage
        rust
        {
          config = mkConfig "sloe" "x86_64-linux" "server" {

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

  flake.nixosConfigurations.blackwell = inputs.os.lib.nixosSystem {
    inherit specialArgs;

    modules =
      with inputs.self.modules.nixos;
      commonModules
      ++ serverModules
      ++ [
        boot-grub
        disks-disko
        disks-extra-zram-swap
        object-storage
        rust
        {
          config = mkConfig "blackwell" "x86_64-linux" "server" {

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

  flake.darwinConfigurations.lime = inputs.os-darwin.lib.darwinSystem {
    inherit specialArgs;

    modules = with inputs.self.modules.darwin; [
      app-launcher
      disable-nix-documentation
      hjem
      keys
      lib
      network
      openssh
      packages
      rust-desktop
      secret-manager
      sudo
      system
      tailscale
      theme
      unfree
      users
      {
        config = {
          platform = "aarch64-darwin";
          type = "desktop";

          network.hostName = "lime";

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
