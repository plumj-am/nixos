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
      emacs
      file-manager
      forgejo-cli
      games
      gammastep
      ghostty
      graphics
      hardware-desktop
      haskell
      helium
      keepassxc
      kitty
      # llama-cpp
      # lmstudio
      mprocs
      nextcloud-client
      nuke
      # ollama
      omp
      opencode
      packages
      packages-gui
      packages-cli
      peripherals
      pijul
      process-management
      quickshell
      radicle
      radicle-node
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
