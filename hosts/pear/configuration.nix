{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) enabled;
  inherit (import ../../keys.nix) james;

	interface = "ts0";
in
{

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowUnsupportedSystem = true;

  # agenix configuration
  age.identityPaths = [ "/root/.ssh/id" ];
  age.secrets.id.file = ./id.age;

  wsl = {
    enable = true;
    defaultUser = "james";

    startMenuLaunchers = true;
    useWindowsDriver = true;
    docker-desktop.enable = true;

    # usb passthrough
    usbip = {
      enable = true;
      # autoAttach = [ "1-9" ]; # add device IDs like "4-1" to auto-attach USB devices
    };

    # for usbip
    extraBin = [
      { src = "${lib.getExe' pkgs.coreutils-full "ls"}"; }
      { src = "${lib.getExe pkgs.bash}"; }
      { src = "${lib.getExe' pkgs.linuxPackages.usbip "usbip"}"; }
    ];

    wslConf = {
      automount.root = "/mnt";
      automount.options = "metadata,uid=1000,gid=100,noatime";
      boot.systemd = true;
      interop.enabled = true;
      interop.appendWindowsPath = true;
      network.generateHosts = true;
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      auto-optimise-store = true;
      trusted-users = [ "james" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
    };
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
    openssh.authorizedKeys.keys = [ james ];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [ james ];
  };

  programs = {
  };

  services = {
    openssh = {
      enable = true;
      hostKeys = [{
        type = "ed25519";
        path = config.age.secrets.id.path;
      }];
    };
  };

	services.tailscale = enabled {
		useRoutingFeatures = "both";
		interfaceName = interface;
	};

  networking = {
    hostName = "pear";
    firewall = enabled {
			trustedInterfaces = [ interface ];
		};
  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";

  # this value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Don't change this after installation.
  system.stateVersion = "24.11";
}
