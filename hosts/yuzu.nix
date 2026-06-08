{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Yuzu | desktop | x86_64-linux | NixOS
  flake.nixosConfigurations.yuzu = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      audio
      boot-systemd
      buildbot-worker
      claude-code
      desktop-gui
      desktop-tools
      discord
      disks-normal
      docker-rootless
      editor-extra
      forgejo-cli
      games
      gammastep
      ghostty
      graphics
      harmonia
      hardware-desktop
      haskell
      helium
      jujutsu-extra
      keepassxc
      kitty
      litellm
      llama-cpp
      mprocs
      # ncro
      nix-settings-extra-desktop
      omp
      opencode
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      pi
      pijul
      process-management
      quickshell
      radicle
      radicle-gui
      radicle-node
      radicle-tui
      raperl
      rio
      rust-desktop
      rss-tui
      sudo-extra-desktop
      syncthing
      swap-partition
      s3-upload
      theme-extra-fonts
      theme-extra-scripts
      window-manager
      zellij
      zyouz
      { hardware.facter.reportPath = ./facter/yuzu.json; }
      {
        config = mkConfig inputs "yuzu" "x86_64-linux" {
          systemInfo = {
            cores = 20;

            disks.swap.partition = {
              path = "/dev/disk/by-label/swap";
              size = "34G";
            };
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";
          age.secrets = {
            nixStoreKey.rekeyFile = ../secrets/yuzu-nix-store-key.age;
            radicleUserKey = {
              rekeyFile = ../secrets/yuzu-radicle-user-key.age;
              owner = "jam";
              mode = "600";
            };
            rssApiPassword = {
              rekeyFile = ../secrets/plum-rss-api-password.age;
              owner = "jam";
              mode = "600";
            };
            resticPassword.rekeyFile = ../secrets/restic-password.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
