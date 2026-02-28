let
  gammastepBase =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;

      ini = pkgs.formats.ini { };

      settings = {
        general = {
          location-provider = "geoclue2";
          temp-day = 5500;
          temp-night = 3500;
        };
      };
    in
    {
      services.geoclue2.enable = true;

      hjem.extraModules = singleton {
        packages = singleton pkgs.gammastep;

        xdg.config.files."gammastep/config.ini".source = ini.generate "gammastep-config.ini" settings;
      };
    };

in
{
  flake.modules.nixos.gammastep = gammastepBase;
}
