{ lib, config, ... }: let
  inherit (lib) enabled mkIf optionalString;
in {
  security.sudo = enabled {
    execWheelOnly = true;
    extraConfig   = /* sudo */ ''
      Defaults pwfeedback
      Defaults lecture = never
      Defaults env_keep += "DISPLAY EDITOR PATH"
      ${optionalString config.isServer /* sudo */ ''
        Defaults timestamp_timeout = 0
      ''}
    '';

    wheelNeedsPassword = mkIf config.isDesktop false;
  };

}
