lib: let
  inherit (lib) inputs enabled;
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
          ./hardware.nix
        ];

        type                        = "desktop";
        isGaming                    = true;
        nixpkgs.hostPlatform.system = "x86_64-linux";

        # Allow unfree packages for gaming and graphics
        unfree.allowedNames = [
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
          "steam"
          "steam-original"
          "steam-unwrapped"
          "steamPackages.steam"
        ];

        age.rekey = {
          hostPubkey       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDLlddona4PlORWd+QpR/7F5H46/Dic9vV23/YSrZl0 root@yuzu";
          masterIdentities = [ (self + /yubikey.pub) ];
          localStorageDir  = self + "/hosts/${config.networking.hostName}/rekeyed";
          storageMode      = "local";
        };

        age.secrets.id.rekeyFile = ./id.age;
        services.openssh         = enabled {
          hostKeys = [{
            type = "ed25519";
            path = config.age.secrets.id.path;
          }];
          settings = {
            PasswordAuthentication       = false;
            KbdInteractiveAuthentication = false;
            AcceptEnv                    = "SHELLS COLORTERM";
          };
        };

        age.secrets.password.rekeyFile = ./password.age;
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
            extraGroups                 = [ "wheel" "networkmanager" ];
          };
        };

        home-manager.users = {
          root = {};
          jam  = {};
        };

        networking = {
          hostName   = "yuzu";
          firewall   = enabled {
            trustedInterfaces = [ interface ];
            allowedTCPPorts   = [ 22 ];
          };
          useDHCP    = lib.mkDefault true;
          interfaces = {};
        };

        # Ignore power button short presses.
        services.logind.settings.Login.HandlePowerKey = "ignore";

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
