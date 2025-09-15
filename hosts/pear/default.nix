lib:
let
  inherit (lib) inputs enabled;
  interface = "ts0";
in {
  class  = "nixos";
  config = lib.nixosSystem' {
    system  = "x86_64-linux";
    modules = [
      inputs.nixos-wsl.nixosModules.wsl
      ({ pkgs, lib, config, keys, self, ... }: {
        imports = [
          (self + /modules/system.nix)
          (self + /modules/nix.nix)
        ];

        security.sudo = enabled {
          execWheelOnly = true;
        };

        nixpkgs.hostPlatform.system = "x86_64-linux";
        nixpkgs.config.allowUnfree  = true;

        type  = "desktop";
        isWsl = true;

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

        age.identityPaths   = [ "/root/.ssh/id" ];
        age.secrets.id.file = ./id.age;

        wsl = enabled {
          defaultUser = "james";

          startMenuLaunchers    = true;
          useWindowsDriver      = true;
          docker-desktop.enable = true;

          # usb passthrough
          usbip = enabled {
            # autoAttach = [ "1-9" ]; # add device IDs like "4-1" to auto-attach USB devices
          };

          # for usbip
          extraBin = [
            { src = "${lib.getExe' pkgs.coreutils-full "ls"}"; }
            { src = "${lib.getExe pkgs.bash}"; }
            { src = "${lib.getExe' pkgs.linuxPackages.usbip "usbip"}"; }
          ];

          wslConf = {
            automount.root            = "/mnt";
            automount.options         = "metadata,uid=1000,gid=100,noatime";
            boot.systemd              = true;
            interop.enabled           = true;
            interop.appendWindowsPath = true;
            network.generateHosts     = true;
          };
        };

        users.users.james = {
          isNormalUser = true;
          shell        = pkgs.nushell;
          extraGroups  = [ "wheel" "docker" "dialout" ];
          openssh.authorizedKeys.keys = [ keys.james ];
        };

        users.users.root.openssh.authorizedKeys.keys = [ keys.james ];

        users.groups.build = {};

        users.users.build = {
          description                 = "Build";
          openssh.authorizedKeys.keys = [ keys.james ];
          isNormalUser                = true;
          extraGroups                 = [ "build" ];
        };

        home-manager.users = {
          james = {};
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
          hostName   = "pear";
          firewall   = enabled {
            trustedInterfaces = [ interface ];
            allowedTCPPorts   = [ 22 ];
          };
          useDHCP    = lib.mkDefault true;
          interfaces = {};
        };

        system.stateVersion = "24.11";
      })
    ];
  };
}
