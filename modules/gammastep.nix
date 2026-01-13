{
  config.flake.modules.nixos.gammastep = {
    services.geoclue2.enable = true;
  };
  config.flake.modules.hjem.gammastep = {
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
