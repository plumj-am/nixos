{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.gammastep;
  flake.modules.nixos.gammastep =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.localisation) location;
    in
    {
      environment.systemPackages = singleton pkgs.gammastep;

      hjemModule = {
        xdg.config.files."gammastep/config.ini" = {
          generator = lib.generators.toINI { };
          value = {
            general = {
              temp-day = 4500;
              temp-night = 3500;
              location-provider = "manual";
            };

            manual = {
              lat = location.latitude;
              lon = location.longitude;
            };
          };
        };
      };
    };
}
