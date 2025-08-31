{ pkgs, lib, modulesPath, config, ... }:
let
	inherit (lib) enabled;
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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4"
    ];
  };

	users.users.root = {
		openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4"
		];
		hashedPasswordFile = config.age.secrets.password.path;
	};

	home-manager.users = {
		james = {};
	};

  services.openssh = {
    enable = true;
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

  networking = {
    hostName = "kiwi";
    firewall = {
      enable = true;
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
