let
  makoBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;
      inherit (config.networking) hostName;

      soundTheme = pkgs.sound-theme-freedesktop;
    in
    {
      hjem.extraModules = singleton {
        packages = [
          pkgs.libnotify
          pkgs.mako
          pkgs.pulseaudio # for paplay
          soundTheme
        ];

        # Symlink sounds to a consistent location for mako
        xdg.data.files."sounds/freedesktop".source = "${soundTheme}/share/sounds/freedesktop";

        # Can't use a generator here for some reason.
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

            # 75% volume - max (and default) = 65536
            on-notify=exec paplay --volume 49152 ~/.local/share/sounds/freedesktop/stereo/message.oga

            border-size=${toString border.small}
            border-radius=${toString radius.small}

            background-color=#${colors.base00}FF
            text-color=#${colors.base07}FF
            border-color=#${colors.base0A}BB
            progress-color=over #${colors.base09}55

            [mode=do-not-disturb]
            invisible=1

            [mode=mute]
            on-notify=exec nu -c "null"

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
    };
in
{
  flake.modules.nixos.notifications = makoBase;
}
