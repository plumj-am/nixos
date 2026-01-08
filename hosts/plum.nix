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

          (self + /modules/nix.nix)
          (self + /modules/site.nix)
          (self + /modules/system.nix)

          (self + /modules/forgejo.nix)
          (self + /modules/matrix)
          (self + /modules/uptime-kuma.nix)
          (self + /modules/goatcounter.nix)
          (self + /modules/grafana)
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
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";
        };

        openssh = enabled {
          idFile = self + /secrets/plum-id.age;
        };

        network = enabled {
          hostName = "plum";
          domain   = "plumj.am";
          tcpPorts = [ 22 80 443 ];
        };


        systemd.services.sshd = {
          after = [ "agenix.service" ];
          wants = [ "agenix.service" ];
        };

        customUsers = enabled {
          passwordFile = self + /secrets/plum-password.age;
          buildUser = true;
          forgejoUser = true;
        };

        age.secrets.acmeEnvironment.rekeyFile = self + /secrets/acme-environment.age;

        age.secrets.z-ai-key2 = {
          rekeyFile = self + /secrets/z-ai-key.age;
        };

        age.secrets.nixServeKey = {
          rekeyFile = self + /secrets/plum-cache-key.age;
          owner     = "root";
        };
        cache = enabled {
          fqdn          = "cache1.${config.networking.domain}";
          secretKeyFile = config.age.secrets.nixServeKey.path;
        };

        age.secrets.forgejoRunnerToken.rekeyFile = self + /secrets/plum-forgejo-runner-token.age;
        ci-runner = enabled {
          tokenFile  = config.age.secrets.forgejoRunnerToken.path;
          url        = "https://git.plumj.am/";
          labels     = [
            "plum:host"
            "docpad-infra:host"
            "self-hosted:host"
          ];
          withDocker = true;
        };

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
