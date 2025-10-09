{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf enabled;
in mkIf config.isDesktopNotWsl {

  environment.systemPackages = [ pkgs.libnotify ]; # Provides `notify-send`.

  home-manager.sharedModules = [{
    services.mako = with config.theme; enabled {

      settings = {
        icons         = true;
        max-icon-size = 32;

        font = "${font.mono.name} ${toString font.size.small}";

        # Format: `bold app, bold summary, body`.
        format = "<b>%s</b>\\n%b";
        markup = true;

        anchor  = "top-right";
        layer   = "overlay";
        width   = 400;
        height  = 150;
        margin  = "${toString margin.normal}";
        padding = "${toString padding.normal}";

        # output = mkIf (config.networking.hostName == "yuzu") "DP-1";

        sort        = "-time";
        max-visible = 10;
        group-by    = "app-name";

        border-size   = border.normal;
        border-radius = radius.verybig;

        background-color = "#${colors.base00}FF";
        text-color       = "#${colors.base07}FF";
        border-color     = "#${colors.base0A}BB";
        progress-color   = "over #${colors.base09}55";

        default-timeout = 20000;
      };

      extraConfig = /* ini */ ''
        [urgency=low]
        border-color=#${colors.base0E}FF
        default-timeout=10000

        [urgency=normal]
        border-color=#${colors.base0A}FF
        default-timeout=20000

        [urgency=critical]
        border-color=#${colors.base08}FF
        default-timeout=30000
      '';
    };
  }];
}
