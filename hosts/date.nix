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
      boot-systemd
      buildbot-worker
      # circus-agent
      # circus-evaluator
      colour-picker
      claude-code
      desktop-gui
      discord
      disks-bcachefs
      docker-rootless
      editor-extra
      file-manager
      forgejo-action-runner
      forgejo-cli
      games
      gammastep
      graphics
      harmonia
      hardware-desktop
      helium
      jujutsu-extra
      keepassxc
      kitty
      litellm
      mprocs
      # ncro
      nextcloud-client
      nix-settings-extra-desktop
      opencode
      packages-extra-linux
      packages-extra-gui
      packages-extra-cli
      peripherals
      pi
      process-management
      quickshell
      rust-desktop
      rss-tui
      sops
      sudo-desktop
      syncthing
      swap-partition
      s3-upload
      theme-extra-fonts
      theme-extra-scripts
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
            ciRunner.strong = true;

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
