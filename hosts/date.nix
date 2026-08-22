{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Date | laptop/server | x86_64-linux | NixOS
  flake.nixosConfigurations.date = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      audio
      boot-optimise
      boot-systemd
      brave
      colour-picker
      desktop-gui
      discord
      disks-normal
      docker-rootless
      editor-extra
      file-manager
      forgejo-runner
      forgejo-cli
      games
      gammastep
      graphics
      harmonia
      hardware-desktop
      helium
      keepassxc
      kitty
      mprocs
      nextcloud-client
      nix-settings-extra-desktop
      omp
      opencode
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      process-management
      quickshell
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
      { hardware.facter.reportPath = ./facter/date.json; }
      {
        config = mkConfig inputs "date" "x86_64-linux" {
          systemInfo = {
            cores = 12;
            distributedBuilder = {
              enable = true;
              speedFactor = 4;
            };

            disks.swap.partition = {
              path = "/dev/disk/by-label/swap";
              size = "18G";
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
}
