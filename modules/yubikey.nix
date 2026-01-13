{
  flake.modules.hjem.yubikey =
    {
      pkgs,
      lib,
      isDesktop,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      packages = [
        pkgs.yubikey-personalization
        pkgs.yubioath-flutter
        pkgs.age-plugin-yubikey
      ];
    in
    mkIf isDesktop {
      inherit packages;
    };

  flake.modules.nixos.yubikey =
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

  flake.modules.darwin.yubikey =
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
