lib:
let
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

          ./disk.nix
          ./cache/default.nix
          ./grafana
          ./grafana/prometheus.nix
          ./uptime-kuma
          ./goatcounter
          (self + /modules/forgejo.nix)
          (self + /modules/site.nix)
          (self + /modules/matrix.nix)
          (self + /modules/cinny.nix)
          (self + /modules/system.nix)
          (self + /modules/nix.nix)
        ];

        nixpkgs.hostPlatform.system = "x86_64-linux";

        type = "server";

        services.openssh = enabled {
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

        age.secrets.password.file = ./password.age;
        age.secrets.id.file       = ./id.age;

        users.users.jam = {
          isNormalUser       = true;
          shell              = pkgs.nushell;
          hashedPasswordFile = config.age.secrets.password.path;
          extraGroups        = [ "wheel" ];
          openssh.authorizedKeys.keys = [ keys.jam ];
        };

        users.users.root = {
          openssh.authorizedKeys.keys = [ keys.jam ];
          hashedPasswordFile          = config.age.secrets.password.path;
        };

        users.groups.build = {};

        users.users.build = {
          description                 = "Build";
          openssh.authorizedKeys.keys = keys.all;
          isNormalUser                = true;
          createHome                  = false;
          group                       = "build";
        };

        home-manager.users = {
          jam = {};
        };

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

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

        system.stateVersion = "24.11";
      })
    ];
  };
}
