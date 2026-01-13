{
  flake.modules.nixos.gammastep = {
    services.geoclue2.enable = true;
  };
  flake.modules.hjem.gammastep =
    {
      lib,
      isDesktop,
      ...

    }:
    let
      inherit (lib.modules) mkIf;
    in
    mkIf isDesktop {
      rum.programs.gammastep = {
        enable = true;

        settings.general = {
          location-provider = "geoclue2";
          temp-day = 4500;
          temp-night = 3500;
        };
      };
    };
}
