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

          (self + /modules/forgejo.nix)
          (self + /modules/site.nix)
          (self + /modules/matrix.nix)
          (self + /modules/cinny.nix)
          (self + /modules/system.nix)
          (self + /modules/nix.nix)
          ./disk.nix
          ./cache/default.nix
          ./grafana
          ./grafana/prometheus.nix
          ./uptime-kuma
          ./goatcounter
        ];

        type                        = "server";
        nixpkgs.hostPlatform.system = "x86_64-linux";

        age.secrets.id.file = ./id.age;
        services.openssh    = enabled {
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

        age.secrets.password.file = ./password.age;
        users.users               = {
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

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
