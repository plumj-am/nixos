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

      ai-extra
      audio
      boot-systemd
      claude-code
      desktop-gui
      desktop-tools
      discord
      disks-bcachefs
      disks-extra-zram-swap
      docker-rootless
      editor-extra
      forgejo-action-runner
      forgejo-cli
      games
      gammastep
      graphics
      hardware-desktop
      jujutsu-extra
      kitty
      litellm
      mprocs
      nix-settings-extra-desktop
      nix-distributed-builder
      nix-distributed-builds
      object-storage
      opencode
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      process-management
      quickshell
      rust-desktop
      rss-tui
      sudo-extra-desktop
      syncthing
      theme-extra-fonts
      theme-extra-scripts
      window-manager
      zellij
      { hardware.facter.reportPath = ./facter/date.json; }
      {
        config = mkConfig inputs "date" "x86_64-linux" {
          diskConfig.swapSize = "18G";

          nix-builder = {
            cores = 8;
            speedFactor = 4;
          };

          forgejo-action-runner = {
            strong = true;
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfoVKZDyiyyMiX1JRFaaTELspG25MlLNq0kI2AANTa root@date";
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
}
