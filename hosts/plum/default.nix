lib: let
  inherit (lib) inputs enabled;
  interface = "ts0";
in {
  class  = "nixos";
  config = lib.nixosSystem' {
    system  = "x86_64-linux";
    modules = [
      inputs.disko.nixosModules.disko
      ({ pkgs, lib, modulesPath, config, keys, self, ... }: {
        imports = [
          # hetzner
          (modulesPath + "/installer/scan/not-detected.nix")
          (modulesPath + "/profiles/qemu-guest.nix")

          (self + /modules/nix.nix)
          (self + /modules/site.nix)
          (self + /modules/system.nix)

          ./cache
          ./disk.nix
          ./forgejo
          ./git-runners
          ./goatcounter
          ./grafana
          ./matrix
          ./uptime-kuma
        ];

        type                        = "server";
        nixpkgs.hostPlatform.system = "x86_64-linux";

        age.rekey = {
          hostPubkey       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";
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

        systemd.services.sshd = {
          after = [ "agenix.service" ];
          wants = [ "agenix.service" ];
        };

        age.secrets.password.rekeyFile = ./password.age;
        users.users                    = {
          root = {
            shell                       = pkgs.nushell;
            openssh.authorizedKeys.keys = keys.admins;
            hashedPasswordFile          = config.age.secrets.password.path;
          };

          jam = {
            description                 = "Jam";
            isNormalUser                = true;
            shell                       = pkgs.nushell;
            hashedPasswordFile          = config.age.secrets.password.path;
            openssh.authorizedKeys.keys = keys.admins;
            extraGroups                 = [ "wheel" ];
          };

          build = {
            description                 = "Build";
            isNormalUser                = true;
            createHome                  = false;
            openssh.authorizedKeys.keys = keys.all;
            extraGroups                 = [ "build" ];
          };

          forgejo = {
            description                 = "Forgejo";
            createHome                  = false;
            openssh.authorizedKeys.keys = keys.admins;
          };
        };

        home-manager.users = {
          root = {};
          jam  = {};
        };

        networking = {
          hostName   = "plum";
          domain     = "plumj.am";
          firewall   = enabled {
            trustedInterfaces = [ interface ];
            allowedTCPPorts   = [ 22 80 443 ];
          };
          useDHCP    = lib.mkDefault true;
          interfaces = {};
        };

        age.secrets.acmeEnvironment.rekeyFile = self + /modules/acme/environment.age;


        age.secrets.forgejoAdminPassword = {
          rekeyFile = ./forgejo-password.age;
          owner     = "forgejo";
        };

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
