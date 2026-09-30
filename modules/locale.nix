{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.locale;
  flake.modules.nixos.locale =
    { lib, config, ... }:
    let
      inherit (lib.options) mkOptionOf;
      inherit (lib.types) enum float str;

      cfg = config.localisation;
    in
    {
      options.localisation = {
        time_zone = mkOptionOf str {
          default = "Europe/Warsaw";
          description = "IANA time zone identifier";
        };

        i18n = mkOptionOf str {
          default = "en_US.UTF-8";
          description = "i18n locale string";
        };

        location = {
          latitude = mkOptionOf float {
            default = 52.23;
            description = "approximate latitude of current location";
          };
          longitude = mkOptionOf float {
            default = 52.23;
            description = "approximate longitude of current location";
          };
        };

        units = {
          system =
            mkOptionOf
              (enum [
                "metric"
                "imperial"
              ])
              {
                default = "metric";
                description = "unit system to use";
              };
          temperature =
            mkOptionOf
              (enum [
                "celcius"
                "fahrenheit"
              ])
              {
                default = "celcius";
                description = "temperature unit to use";
              };
          temperature_short =
            mkOptionOf
              (enum [
                "C"
                "F"
              ])
              {
                default = if cfg.units.temperature == "fahrenheit" then "F" else "C";
                description = "temperature unit to use";
              };
        };
      };

      config = {
        time.timeZone = cfg.time_zone;
        i18n.defaultLocale = cfg.i18n;

        # Fallbacks for different detection methods.
        environment.etc."timezone".text = cfg.time_zone;
        environment.sessionVariables.TZ = cfg.time_zone;
        systemd.globalEnvironment.TZ = cfg.time_zone;
      };
    };
}
