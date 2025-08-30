{ pkgs, lib, modulesPath, ... }:
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk.nix
	];

	boot.loader.grub = {
		efiSupport = true;
		efiInstallAsRemovable = true;
	};

  # user configuration
  users.users.james = {
    isNormalUser = true;
    shell = pkgs.nushell; # nushell as default shell
    extraGroups = [
      "wheel" # sudo access
      "docker" # if using Docker
      "dialout"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7WV4+7uhIWQVHEN/2K0jJPTaZ/HbG3W8OKSpzmPBI4"
    ];
  };

	users.users.root.openssh.authorizedKeys.keys = [
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE0LRmns5YhIUkmr4DCJPUeLKs6aDFNTeXBhrQoTxpme"
	];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
      PubkeyAuthentication = true;
    };
    openFirewall = true;
  };

  networking = {
    hostName = "plum";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";

  # this value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Don't change this after installation.
  system.stateVersion = "24.11";
}
