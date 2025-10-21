{ pkgs, lib, config, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktop {
  services.pcscd                  = enabled;
  programs.yubikey-manager        = enabled;
  programs.yubikey-touch-detector = enabled {
    libnotify = true;
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth  = true;
    su.u2fAuth    = true;
  };

  environment.systemPackages = [
    pkgs.yubikey-personalization
    pkgs.yubioath-flutter
    pkgs.age-plugin-yubikey
  ];

  services.udev.packages = [
    pkgs.yubikey-personalization
  ];

  home-manager.sharedModules = [{


  }];
}
