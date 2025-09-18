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

        nixpkgs.hostPlatform.system = "x86_64-linux";

        type  = "desktop";
        isWsl = true;

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
        age.secrets.id.file = ./id.age;

        wsl = enabled {
          defaultUser = "jam";

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
            interop.appendWindowsPath = false;
            network.generateHosts     = true;
          };
        };

        users.users.jam = {
          isNormalUser = true;
          shell        = pkgs.nushell;
          hashedPasswordFile = config.age.secrets.password.path;
          extraGroups  = [ "wheel" "docker" "dialout" ];
          openssh.authorizedKeys.keys = [ keys.jam ];
        };

        users.users.root = {
          openssh.authorizedKeys.keys = [ keys.jam ];
          hashedPasswordFile = config.age.secrets.password.path;
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
