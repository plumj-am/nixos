{
  config.flake.modules.nixos.sudo-desktop = {
    security.sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = false;
      extraConfig = # sudo
        ''
          Defaults pwfeedback
          Defaults !lecture
          Defaults env_keep+="DISPLAY EDITOR PATH"
        '';
    };
  };

  config.flake.modules.nixos.sudo-server = {
    security.sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = false;
      extraConfig = # sudo
        ''
          Defaults pwfeedback
          Defaults !lecture
          Defaults env_keep+="DISPLAY EDITOR PATH"
          Defaults timestamp_timeout = 0
        '';
    };
  };

  config.flake.modules.darwin.sudo = {
    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };
  };
}
