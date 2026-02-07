let
  sudoExtraConfig = # sudo
    ''
      Defaults pwfeedback
      Defaults !lecture
      Defaults env_keep+="DISPLAY EDITOR PATH"
    '';

  sudoBaseLinux = {
    security.sudo-rs = {
      enable = true;
      execWheelOnly = true;
    };
  };

  sudoBaseDarwin = {
    security.sudo.extraConfig = sudoExtraConfig;

    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };
  };

  sudoExtraDesktop = {
    security.sudo-rs = {
      wheelNeedsPassword = false;
      extraConfig = sudoExtraConfig;
    };
  };

  sudoExtraServer = {
    security.sudo-rs = {
      wheelNeedsPassword = true;
      extraConfig = # sudo
        ''
          ${sudoExtraConfig}
          Defaults timestamp_timeout = 0
        '';
    };
  };

in
{
  flake.modules.nixos.sudo = sudoBaseLinux;
  flake.modules.darwin.sudo = sudoBaseDarwin;

  flake.modules.nixos.sudo-extra-desktop = sudoExtraDesktop;
  flake.modules.nixos.sudo-extra-server = sudoExtraServer;
}
