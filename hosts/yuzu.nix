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
      editor-extra
      games
      gammastep
      graphics
      hardware-desktop
      haskell
      hyprlock
      jujutsu-extra
      kitty
      linux-kernel-zen
      # lix
      mprocs
      nix-cache-proxy
      nix-distributed-builds
      nix-settings-extra-desktop
      notifications
      object-storage
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      pijul
      process-management
      quickshell
      radicle
      radicle-gui
      radicle-node
      radicle-tui
      rust-desktop
      rss-tui
      sudo-extra-desktop
      syncthing
      theme-extra-fonts
      theme-extra-scripts
      window-manager
      yazi
      zed
      zellij
      {
        config = mkConfig inputs "yuzu" "x86_64-linux" "desktop" {
          nix-cache-proxy.publicKey = "cache-proxy-yuzu:6dj2bWMTi/ScnDAilNuo/xERm5VZIa1/OUeBm0fUO3g=";

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
