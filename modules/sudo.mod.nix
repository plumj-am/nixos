{
  config.flake.modules.nixosModules.sudo =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
    in
    {
      security.sudo-rs = {
        enable = true;
        execWheelOnly = true;
        extraConfig = # sudo
          ''
            Defaults pwfeedback
            Defaults !lecture
            Defaults env_keep+="DISPLAY EDITOR PATH"
            ${lib.optionalString config.isServer # sudo
              ''
                Defaults timestamp_timeout = 0
              ''
            }
          '';

        wheelNeedsPassword = mkIf (config.type != "desktop") false;
      };
    };

  config.flake.modules.darwinModules.sudo = {
    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };
  };
}
