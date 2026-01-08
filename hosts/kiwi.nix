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
          (self + /modules/network.nix)
          (self + /modules/users.nix)

        ];

        type                        = "server";
        nixpkgs.hostPlatform.system = "x86_64-linux";

        age-rekey = enabled {
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElcSHxI64xqUUKEY83tKyzEH+fYT5JCWn3qCqtw16af root@kiwi";
        };

        openssh = enabled {
          idFile = self + /secrets/kiwi-id.age;
        };

        network = enabled {
          hostName = "kiwi";
          domain   = "dr-radka.pl";
          tcpPorts = [ 22 80 443 ];
        };

        systemd.services.sshd = {
          after = [ "agenix.service" ];
          wants = [ "agenix.service" ];
        };

        customUsers = enabled {
          passwordFile = self + /secrets/kiwi-password.age;
          buildUser = true;
        };

        age.secrets.acmeEnvironment.rekeyFile = self + /secrets/acme-environment.age;

        age.secrets.dr-radka-environment = {
          rekeyFile = self + /secrets/kiwi-dr-radka-environment.age;
          owner     = "dr-radka";
          group     = "dr-radka";
        };

        cache = enabled {
          fqdn          = "cache2.plumj.am";
          secretKeyFile = self + /secrets/kiwi-cache-key.age;
        };

        ci-runner = enabled {
          tokenFile  = self + /secrets/plum-forgejo-runner-token.age;
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
