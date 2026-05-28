{
  flake.modules.nixos.locale =
    let
      tz = "Europe/Warsaw";
    in
    {
      time.timeZone = tz;
      i18n.defaultLocale = "en_US.UTF-8";

      # Fallbacks for different detection methods.
      environment.etc."timezone".text = tz;
      environment.sessionVariables.TZ = tz;
      systemd.globalEnvironment.TZ = tz;
    };
}
