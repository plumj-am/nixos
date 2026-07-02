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
      claude-code
      colour-picker
      desktop-gui
      discord
      disks-normal
      docker-rootless
      editor-extra
      file-manager
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
      nextcloud-client
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
      rust
      rust-desktop
      rss-tui
      sops
      sudo-desktop
      syncthing
      swap-partition
      s3-upload
      theme-extra-fonts
      theme-extra-scripts
      tmux
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

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
