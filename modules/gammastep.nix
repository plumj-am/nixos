{
  flake.modules.nixos.gammastep = {
    services.geoclue2.enable = true;
  };

  flake.modules.hjem.gammastep =
    {
      pkgs,
      lib,
      isDesktop,
      ...

    }:
    let
      inherit (lib.modules) mkIf;

      settings = {
        general = {
          location-provider = "geoclue2";
          temp-day = 4500;
          temp-night = 3500;
        };
      };

      ini = pkgs.formats.ini { };
    in
    mkIf isDesktop {
      packages = [ pkgs.gammastep ];

      xdg.config.files."gammastep/config.ini".source = ini.generate "gammastep-config.ini" settings;
    };
}
