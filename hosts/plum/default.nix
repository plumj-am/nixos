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

          ./matrix
          ./uptime-kuma
          (self + /modules/forgejo.nix)
          (self + /modules/grafana)
          (self + /modules/cache.nix)
          (self + /modules/ci-runners.nix)
        ];

        type                        = "server";
        nixpkgs.hostPlatform.system = "x86_64-linux";

        age.rekey = {
          hostPubkey       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBH1S3dhOYCCltqrseHc3YZFHc9XU90PsvDo7frzUGrr root@plum";
          masterIdentities = [ (self + /yubikey.pub) ];
          localStorageDir  = self + "/hosts/${config.networking.hostName}/rekeyed";
          storageMode      = "local";
        };

        age.secrets.id.rekeyFile = self + /secrets/plum-id.age;
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

        age.secrets.password.rekeyFile = self + /secrets/plum-password.age;
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
