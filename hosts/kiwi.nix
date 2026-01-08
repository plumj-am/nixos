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
          (self + /modules/server-disks.nix)

          (self + /modules/dr-radka.nix)
          (self + /modules/nix.nix)
          (self + /modules/system.nix)
          (self + /modules/cache.nix)
          (self + /modules/ci-runners.nix)
          (self + /modules/openssh.nix)
          (self + /modules/age-rekey.nix)
        ];

        type                        = "server";
        nixpkgs.hostPlatform.system = "x86_64-linux";

        age-rekey = enabled {
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af root@kiwi";
        };

        openssh = enabled {
          idFile = self + /secrets/kiwi-id.age;
        };

        systemd.services.sshd = {
          after = [ "agenix.service" ];
          wants = [ "agenix.service" ];
        };

        age.secrets.password.rekeyFile = self + /secrets/kiwi-password.age;
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

        age.secrets.acmeEnvironment.rekeyFile = self + /secrets/acme-environment.age;

        age.secrets.dr-radka-environment = {
          rekeyFile = self + /secrets/kiwi-dr-radka-environment.age;
          owner     = "dr-radka";
          group     = "dr-radka";
        };

        age.secrets.nixServeKey = {
          rekeyFile = self + /secrets/kiwi-cache-key.age;
          owner     = "root";
        };
        cache = enabled {
          fqdn          = "cache2.plumj.am";
          secretKeyFile = config.age.secrets.nixServeKey.path;
        };

        age.secrets.forgejoRunnerToken.rekeyFile = self + /secrets/plum-forgejo-runner-token.age;
        ci-runner = enabled {
          tokenFile  = config.age.secrets.forgejoRunnerToken.path;
          url        = "https://git.plumj.am/";
          labels     = [
            "kiwi:host"
            "docpad-infra:host"
            "self-hosted:host"
          ];
        };

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
