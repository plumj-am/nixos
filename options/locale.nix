{ self, ... }:
{
  flake.modules.nixos.locale = self.modules.nixos.locale-options;
  flake.modules.nixos.locale-options =
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
    };
}
