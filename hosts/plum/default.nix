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
          ./plausible
          (self + /modules/forgejo.nix)
          (self + /modules/site.nix)
          (self + /modules/matrix.nix)
          (self + /modules/element.nix)
          (self + /modules/linux/node-exporter.nix)
          (self + /modules/system.nix)
          (self + /modules/nix.nix)
        ];

        security.sudo = enabled {
          execWheelOnly = true;
        };

        nixpkgs.hostPlatform.system = "x86_64-linux";

        time.timeZone      = "Europe/Warsaw";
        i18n.defaultLocale = "en_US.UTF-8";

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

        boot.loader.grub = {
          efiSupport            = true;
          efiInstallAsRemovable = true;
        };

        zramSwap = enabled;

        age.identityPaths         = [ "/root/.ssh/id" ];
        age.secrets.password.file = ./password.age;
        age.secrets.id.file       = ./id.age;

        users.mutableUsers = false;

        users.users.james = {
          isNormalUser       = true;
          shell              = pkgs.nushell;
          hashedPasswordFile = config.age.secrets.password.path;
          extraGroups        = [ "wheel" ];
          openssh.authorizedKeys.keys = [ keys.james ];
        };

        users.users.root = {
          openssh.authorizedKeys.keys = [ keys.james ];
          hashedPasswordFile          = config.age.secrets.password.path;
        };

        users.groups.build = {};

        users.users.build = {
          description                 = "Build";
          openssh.authorizedKeys.keys = [ keys.james ];
          hashedPasswordFile          = config.age.secrets.password.path;
          isNormalUser                = true;
          extraGroups                 = [ "build" ];
        };

        home-manager.users = {
          james = {
            imports = [ inputs.nvf.homeManagerModules.default ];
          };
        };

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        programs.mosh = enabled {
          openFirewall = true;
        };

        services.resolved.domains = ["taild29fec.ts.net"];

        services.tailscale = enabled {
          useRoutingFeatures = "both";
          interfaceName      = interface;
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

        system.stateVersion = "24.11";
      })
    ];
  };
}
