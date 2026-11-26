{ self, ... }:
{
  flake.nixosModules.desktop = self.nixosModules.yubikey;
  flake.nixosModules.yubikey =
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
    };
}
