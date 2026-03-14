{ inputs, ... }:
let
  inherit (inputs.self) mkConfig;
in
{
  # Pear | WSL | x86_64-linux | NixOS-WSL
  flake.nixosConfigurations.pear = inputs.os.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = with inputs.self.modules.nixos; [
      aspectsBase

      desktop-tools
      jujutsu-extra
      linux-kernel-zen
      nix-distributed-builds
      # object-storage
      sudo-extra-desktop
      wsl
      {
        config = mkConfig inputs "pear" "x86_64-linux" "wsl" {
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ root@pear";

          age.secrets = {
            # TODO
            # nixStoreKey.rekeyFile = ../secrets/yuzu-nix-store-key.age;
          };

          system.stateVersion = "26.05";
        };
      }
    ];
  };
}
