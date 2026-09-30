{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.ulimit;
  flake.modules.nixos.ulimit =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      # TTY, ssh, display manager login, etc.
      security.pam.loginLimits = singleton {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      };

      # everything started by the systemd user manager (most terminals on a desktop).
      systemd.user.settings.Manager.DefaultLimitNOFILE = "65536";

    };
}
