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

          (self + /modules/dr-radka.nix)
          (self + /modules/nix.nix)
          (self + /modules/system.nix)

          ./disk.nix
          ./cache
          ./github2forgejo
          ./git-runners
        ];

        type                        = "server";
        nixpkgs.hostPlatform.system = "x86_64-linux";

        age.rekey = {
          hostPubkey       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af root@kiwi";
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
            AcceptEnv                    = [ "SHELLS" "COLORTERM" ];
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
            hashedPasswordFile          = config.age.secrets.password.path;
            openssh.authorizedKeys.keys = keys.admins;
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

          # I think the service should create it automatically but doesn't appear to.
          # So we create it manually here, as well as the group.
          github2forgejo = {
            isSystemUser                = true;
            createHome                  = false;
            group                       = "github2forgejo";
          };

          gitea-runner = {
            description  = "gitea-runner";
            isSystemUser = true;
            group        = "gitea-runner";
          };
        };

        users.groups = {
          github2forgejo = {};
          gitea-runner   = {};
        };

        home-manager.users = {
          root = {};
          jam  = {};
        };

        networking = {
          hostName   = "kiwi";
          domain     = "dr-radka.pl";
          firewall   = enabled {
            trustedInterfaces = [ interface ];
            allowedTCPPorts   = [ 22 80 443 ];
          };
          useDHCP    = lib.mkDefault true;
          interfaces = {};
        };

        age.secrets.acmeEnvironment.rekeyFile = self + /modules/acme/environment.age;

        age.secrets.dr-radka-environment = {
          rekeyFile = ./dr-radka-environment.age;
          owner     = "dr-radka";
          group     = "dr-radka";
        };

        age.secrets.github2forgejoEnvironment = {
          rekeyFile = ./github2forgejo/environment.age;
          owner     = "github2forgejo";
        };

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
