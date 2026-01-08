{
  config.flake.modules.nixosModules.mouse =
    { lib, config, ... }:
    let
      inherit (lib) mkIf;
    in mkIf config.isDesktop {
      services.libinput = {
        enable = true;
        mouse.leftHanded = true;
        touchpad.leftHanded = true;
      };
    };
}
