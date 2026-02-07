let
  discordTuiBase =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;

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
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.discordo;

        xdg.config.files."discordo/config.toml".source = toml.generate "config.toml" discordoConfig;
      };
    };

  discordGuiBase =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.vesktop;
      };
    };

in
{
  flake.modules.nixos.discord-tui = discordTuiBase;
  flake.modules.darwin.discord-tui = discordTuiBase;

  flake.modules.nixos.discord-gui = discordGuiBase;
  flake.modules.darwin.discord-gui = discordGuiBase;
}
