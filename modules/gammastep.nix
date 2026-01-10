{
  config.flake.modules.hjem.gammastep =
    { pkgs, ... }:
    let
      packages = [
        pkgs.gammastep
        pkgs.geoclue2
      ];
    in
    {
      inherit packages;

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
