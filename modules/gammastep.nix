{
  flake.modules.nixos.gammastep =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      services.geoclue2.enable = true;

      hjem.extraModule = {
        packages = singleton pkgs.gammastep;

        xdg.config.files."gammastep/config.ini" = {
          generator = lib.generators.toINI { };
          value = {
            general = {
              location-provider = "geoclue2";
              temp-day = 4500;
              temp-night = 3500;
            };
          };
        };
      };
    };
}
