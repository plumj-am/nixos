lib: let
  inherit (lib) enabled;
  interface = "ts0";
in {
  class  = "nixos";
  config = lib.nixosSystem' {
    system  = "x86_64-linux";
    modules = [
      ({ pkgs, lib, config, keys, self, ... }: {
        imports = [
          (self + /modules/system.nix)
          (self + /modules/nix.nix)
          (self + /modules/desktop-hardware.nix)
          (self + /modules/openssh.nix)
          (self + /modules/age-rekey.nix)
          (self + /modules/network.nix)
        ];

        type                        = "desktop";
        nixpkgs.hostPlatform.system = "x86_64-linux";

        # Allow unfree packages for graphics
        unfree.allowedNames = [
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
        ];

        age-rekey = enabled {
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfoVKZDyiyyMiX1JRFaaTELspG25MlLNq0kI2AANTa root@date";
        };

        openssh = enabled {
          idFile = self + /secrets/date-id.age;
        };

        network = enabled {
          hostName = "date";
        };

        age.secrets.password.rekeyFile = self + /secrets/date-password.age;
        users.users                    = {
          root = {
            shell                       = pkgs.nushell;
            hashedPasswordFile          = config.age.secrets.password.path;
            openssh.authorizedKeys.keys = keys.admins;
          };

          jam = {
            description                 = "Jam";
            isNormalUser                = true;
            shell                       = pkgs.nushell;
            hashedPasswordFile          = config.age.secrets.password.path;
            openssh.authorizedKeys.keys = keys.admins;
            extraGroups                 = [ "wheel" "networkmanager" "docker" ];
          };
        };

        home-manager.users = {
          root = {};
          jam  = {};
        };

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
