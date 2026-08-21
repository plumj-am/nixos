{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Yuzu | desktop | x86_64-linux | NixOS
  flake.nixosConfigurations.yuzu = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      audio
      boot-optimise
      boot-systemd
      colour-picker
      commandcode
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
      keepassxc
      kitty
      # llama-cpp
      # lmstudio
      mprocs
      nextcloud-client
      nix-settings-extra-desktop
      # ollama
      omp
      opencode
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      pijul
      process-management
      quickshell
      radicle
      radicle-node
      radicle-tui
      raperl
      rio
      rust
      rust-desktop
      shed
      sops
      sudo-desktop
      swap-partition
      s3
      s3-upload
      theme-extra-fonts
      theme-extra-scripts
      tmux
      video-player
      window-manager
      zellij
      zyouz
      { hardware.facter.reportPath = ./facter/yuzu.json; }
      {
        config = mkConfig inputs "yuzu" "x86_64-linux" {
          systemInfo = {
            cores = 14;
            threads = 20;

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
