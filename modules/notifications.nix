{
  config.flake.modules.hjem.notifications =
    {
      pkgs,
      lib,
      theme,
      isLinux,
      hostName,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
    in
    mkIf isLinux {
      packages = [
        pkgs.libnotify
        pkgs.mako
      ];

      xdg.config.files."mako/config".text =
        with theme; # ini
        ''
          icons=true
          max-icon-size=32

          font=${font.sans.name} ${toString font.size.tiny}

          # Format: `bold app, bold summary, body`.
          format=<b>%s</b>\n%b
          markup=true

          anchor=top-right
          layer=top
          width=340
          height=200
          margin=${toString margin.small}
          padding=${toString padding.normal}
          output=${if hostName == "yuzu" then "DP-2" else ""}
          sort=+time
          max-visible=10
          # group-by=app-name
          default-timeout=10000

          border-size=${toString border.small}
          border-radius=${toString radius.small}

          background-color=#${colors.base00}FF
          text-color=#${colors.base07}FF
          border-color=#${colors.base0A}BB
          progress-color=over #${colors.base09}55

          [mode=do-not-disturb]
          invisible=1

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
}
