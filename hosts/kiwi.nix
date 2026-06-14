{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Kiwi | server | x86_64-linux | NixOS
  flake.nixosConfigurations.kiwi = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      acme
      boot-grub
      disks-server
      forgejo-action-runner
      harmonia
      # ncro
      nginx
      nix-settings-extra-server
      radicle-node
      rust
      sops
      sudo-server
      syncthing
      swapfile
      s3-upload
      website-dr-radka
      zellij
      { hardware.facter.reportPath = ./facter/kiwi.json; }
      {
        config = mkConfig inputs "kiwi" "x86_64-linux" {
          networking = {
            domain = "dr-radka.pl";
            firewall.allowedTCPPorts = [
              22
              80
              443
            ];
          };

          systemInfo = {
            cores = 2;
            distributedBuilder = {
              enable = false;
              speedFactor = 2;
            };

            disks.swap.file = {
              path = "/swapfile";
              size = 1024 * 2;
            };
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
