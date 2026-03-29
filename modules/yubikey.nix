let
  yubikeyCommon =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.yubikey-personalization
        pkgs.age-plugin-yubikey
      ];

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
in
{
  flake.modules.nixos.yubikey =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton yubikeyCommon;
      environment.systemPackages = singleton pkgs.yubioath-flutter;
    };

  flake.modules.darwin.yubikey = yubikeyCommon;
}
