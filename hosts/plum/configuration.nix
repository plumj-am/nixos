{ pkgs, lib, modulesPath, config, keys, ... }:
let
	inherit (lib) enabled;

	interface = "ts0";
in
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk.nix
	];

	nix.settings.experimental-features = [ "nix-command" "flakes" "pipe-operators" ];

	security.sudo = enabled {
		execWheelOnly = true;
	};

	boot.loader.grub = {
		efiSupport = true;
		efiInstallAsRemovable = true;
	};

	zramSwap = enabled;

	age.identityPaths = [ "/root/.ssh/id" ];
	age.secrets.password.file = ./password.age;
	age.secrets.id.file = ./id.age;

  # user configuration
  users.mutableUsers = false;
  users.users.james = {
    isNormalUser = true;
    shell = pkgs.nushell; # nushell as default shell
		hashedPasswordFile = config.age.secrets.password.path;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ keys.james ];
  };

	users.users.root = {
		openssh.authorizedKeys.keys = [ keys.james ];
		hashedPasswordFile = config.age.secrets.password.path;
	};

	home-manager.users = {
		james = {};
	};

  services.openssh = enabled {
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      PubkeyAuthentication = true;
    };
    openFirewall = true;
    hostKeys = [{
      type = "ed25519";
      path = config.age.secrets.id.path;
    }];
  };

	services.resolved.domains = ["taild29fec.ts.net"];
	services.tailscale = enabled {
		useRoutingFeatures = "both";
		interfaceName = interface;
	};

  networking = {
    hostName = "plum";
    firewall = enabled {
			trustedInterfaces = [ interface ];
      allowedTCPPorts = [ 22 ];
    };
    useDHCP = lib.mkDefault true;
    interfaces = {};
  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";

  # this value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Don't change this after installation.
  system.stateVersion = "24.11";
}
