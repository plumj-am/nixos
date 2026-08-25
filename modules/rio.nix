{
  flake.modules.common.rio =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (config) theme;

      rioThemes = pkgs.fetchFromGitHub {
        owner = "mbadolato";
        repo = "iTerm2-Color-Schemes";
        rev = "75c93eebaca34a6194ba8bdb83d99b62e20f9aba";
        hash = "sha256-L4H8ZkmI/CHhXOTPo1anTPg73IDS9lUfY6s0yGHaHKM=";
      };
    in
    {
      hjemModule = {
        packages = [
          pkgs.rio

          (pkgs.makeDesktopItem {
            desktopName = "Zellij Rio";
            name = "Zellij-Rio";
            exec = "rio --command zellij";
            terminal = false;
          })
        ];

        xdg.config.files = {
          "rio/config.toml" = {
            generator = pkgs.writers.writeTOML "rio-config.toml";
            value = {
              fonts = {
                size = theme.font.size.normal;
                use-drawable-chars = true;
                family = theme.font.mono.name;
                regular.weight = 400;
                bold.weight = 600;
                italic.weight = 400;
                bold-italic.weight = 600;
                features =
                  if theme.font.mono.name == "Maple Mono NF" then
                    [
                      "+cv64"
                      "+ss03"
                      "+ss05"
                      "+ss07"
                      "+ss08"
                      "+ss09"
                      "+ss10"
                      "+ss11"
                    ]
                  else
                    [ ];
              };
              draw-bold-text-with-light-colors = false;

              shell.program = getExe pkgs.nushell;
              navigation.mode = "Plain";
              scrollback-history-limit = 100000;
              confirm-before-quit = false;

              adaptive-theme = {
                dark = "iterm2-gruvbox-dark-hard";
                light = "iterm2-gruvbox-light-hard";
              };
              hide-mouse-cursor-when-typing = true;
              window.decorations = "Disabled";
              padding = singleton theme.padding.tiny;

              renderer = {
                backend = "Vulkan";
                target_fps = 560;
              };
            };
          };

          "rio/themes/iterm2-gruvbox-dark-hard.toml".source = "${rioThemes}/rio/Gruvbox Dark Hard.toml";
          "rio/themes/iterm2-gruvbox-light-hard.toml".source = "${rioThemes}/rio/Gruvbox Light Hard.toml";
        };
      };
    };
}
