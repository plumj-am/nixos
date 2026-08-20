{
  flake.modules.nixos.gammastep =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule = {
        packages = singleton pkgs.gammastep;

        xdg.config.files."gammastep/config.ini" = {
          generator = lib.generators.toINI { };
          value = {
            general = {
              temp-day = 4500;
              temp-night = 3500;
              location-provider = "manual";
            };

            manual = {
              lat = 52.23;
              lon = 21.01;
            };
          };
        };
      };
    };
}
