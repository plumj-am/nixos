{
  config.flake.modules.homeModules.yubikey =
    { pkgs, ... }:
    let
      packages = [
        pkgs.yubikey-personalization
        pkgs.yubioath-flutter
        pkgs.age-plugin-yubikey
      ];
    in
    {
      inherit packages;
    };

  config.flake.modules.nixosModules.yubikey =
    { pkgs, ... }:
    {
      services.udev.packages = [
        pkgs.yubikey-personalization
      ];

      security.pam.services = {
        login = {
          u2fAuth = true;
          enableGnomeKeyring = true;
        };
        sudo.u2fAuth = true;
        su.u2fAuth = true;
        sshd.u2fAuth = true;
      };

      services.pcscd.enable = true;
      programs.yubikey-manager.enable = true;
      programs.yubikey-touch-detector = {
        enable = true;
        libnotify = true;
      };
    };

  config.flake.modules.darwinModules.yubikey =
    { pkgs, ... }:
    {
      services.udev.packages = [
        pkgs.yubikey-personalization
      ];
      security.pam.services = {
        login = {
          u2fAuth = true;
          enableGnomeKeyring = true;
        };
        sudo.u2fAuth = true;
        su.u2fAuth = true;
        sshd.u2fAuth = true;
      };

      services.pcscd.enable = true;
      programs.yubikey-manager.enable = true;
      programs.yubikey-touch-detector = {
        enable = true;
        libnotify = true;
      };
    };
}
