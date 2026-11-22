{ self, ... }:
{
  flake.nixosModules.default = self.nixosModules.locale;
  flake.nixosModules.locale =
    { config, ... }:
    let
      cfg = config.localisation;
    in
    {
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
