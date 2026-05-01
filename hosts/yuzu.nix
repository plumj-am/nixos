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

      ai-extra
      audio
      boot-systemd
      claude-code
      desktop-gui
      desktop-tools
      discord
      disks-normal
      disks-extra-zram-swap
      docker-rootless
      editor-extra
      forgejo-cli
      games
      gammastep
      graphics
      hardware-desktop
      haskell
      jujutsu-extra
      kitty
      litellm
      llama-cpp
      mprocs
      nix-distributed-builds
      nix-settings-extra-desktop
      object-storage
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
      rust-desktop
      rss-tui
      sudo-extra-desktop
      syncthing
      theme-extra-fonts
      theme-extra-scripts
      window-manager
      zellij
      { hardware.facter.reportPath = ./facter/yuzu.json; }
      {
        config = mkConfig inputs "yuzu" "x86_64-linux" {
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
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
