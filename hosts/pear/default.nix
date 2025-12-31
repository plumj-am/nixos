lib: let
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
          ./backup.nix
        ];

        type                        = "desktop";
        nixpkgs.hostPlatform.system = "x86_64-linux";
        isWsl                       = true;

        age.rekey = {
          hostPubkey       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2/Pg/5ohT3Dacnzjw9pvkeoQ1hEFwG5l1vRkr3v2sQ root@pear";
          masterIdentities = [ (self + /yubikey.pub) ];
          localStorageDir  = self + "/hosts/${config.networking.hostName}/rekeyed";
          storageMode      = "local";
        };

        age.secrets.id.rekeyFile = self + /secrets/pear-id.age;
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
