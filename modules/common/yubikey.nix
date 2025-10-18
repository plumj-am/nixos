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
  };

  environment.systemPackages = [ pkgs.yubioath-flutter ];

  home-manager.sharedModules = [{


  }];
}
