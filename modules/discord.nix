{
  flake.modules.hjem.discord-tui =
    {
      pkgs,
      lib,
      isDesktop,
      ...
    }:
    let
      inherit (lib.modules) mkIf;

      toml = pkgs.formats.toml { };
      discordoConfig = {
        mouse = false;
        status = "invisible";

        typing_indicator.send = false;

        theme = {
          border = {
            enable = true;
            normal_set = "plain";
            active_set = "thick";
            padding = [
              0
              0
              0
              0
            ];
          };

        };

        keybinds = {
          logout = "";
          picker.toggle = "Ctrl+F";
        };

      };
    in
    mkIf isDesktop {
      packages = [
        pkgs.discordo
      ];

      programs.nushell.aliases.dc = "discordo";

      xdg.config.files."discordo/config.toml".source = toml.generate "config.toml" discordoConfig;
    };

  flake.modules.hjem.discord-gui =
    {
      pkgs,
      lib,
      isDesktop,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
    in
    mkIf isDesktop {
      packages = [
        pkgs.vesktop
      ];
    };
}
