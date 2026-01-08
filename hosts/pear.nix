lib: let
  inherit (lib) inputs enabled;
  interface = "ts0";
in {
  class  = "nixos";
  config = lib.nixosSystem' {
    system  = "x86_64-linux";
    modules = [
      inputs.os-wsl.nixosModules.wsl
      ({ pkgs, lib, config, keys, self, ... }: {
        imports = [
          (self + /modules/system.nix)
          (self + /modules/nix.nix)
          (self + /modules/wsl-backup.nix)
          (self + /modules/openssh.nix)
          (self + /modules/age-rekey.nix)
        ];

        type                        = "desktop";
        nixpkgs.hostPlatform.system = "x86_64-linux";
        isWsl                       = true;

        age-rekey = enabled {
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ root@pear";
        };

        openssh = enabled {
          idFile = self + /secrets/pear-id.age;
        };

        wsl = enabled {
          defaultUser            = "jam";
          startMenuLaunchers     = false; # Hide from start menu.
          useWindowsDriver       = true; # Use Windows graphics drivers.
          docker-desktop.enable  = true; # Allow docker-desktop to use NixOS-WSL.

          # Allow USB passthrough.
          usbip = enabled {
            # autoAttach = [ "1-9" ]; # Add device IDs like "4-1" to auto-attach USB devices.
          };

          # Necessary for usbip.
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
            interop.appendWindowsPath = false; # Do not add Windows executables to WSL path.
            network.generateHosts     = true;
          };
        };

        age.secrets.password.rekeyFile = self + /secrets/pear-password.age;
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
            extraGroups                 = [ "wheel" "docker" "dialout" ]; # Dialout for serial, Docker for docker-desktop.
          };
        };

        home-manager.users = {
          root = {};
          jam  = {};
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

        home-manager.sharedModules = [{
          home.stateVersion = "24.11";
        }];

        system.stateVersion = "24.11";
      })
    ];
  };
}
