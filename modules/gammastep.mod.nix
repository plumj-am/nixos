{
  config.flake.modules.homeModules.gammastep =
    { pkgs, ... }:
    let
      packages = [
        pkgs.gammastep
        pkgs.geoclue2
      ];
    in {
      inherit packages;

      programs.gammastep = {
        enable = true;

        settings.general = {
          location-provider = "geoclue2";
          temp-day = 4500;
          temp-night = 3500;
        };
      };
    };
}
