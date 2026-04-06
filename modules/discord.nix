{
  flake.modules.common.discord-tui =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.age) secrets;
    in
    {
      age.secrets.discordToken = {
        rekeyFile = ../secrets/discord-token.age;
        owner = "jam";
        mode = "600";
      };

      hjem.extraModule = {
        packages =
          singleton
          <| pkgs.symlinkJoin {
            name = "discordo-wrapped";
            paths = singleton pkgs.discordo;
            buildInputs = singleton pkgs.makeWrapper;
            postBuild = # sh
              ''
                wrapProgram $out/bin/discordo \
                    --run 'export DISCORDO_TOKEN="$(cat ${secrets.discordToken.path})"'

              '';
          };

        xdg.config.files."discordo/config.toml" = {
          generator = pkgs.writers.writeTOML "discordo-config.toml";
          value = {
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
        };
      };
    };

  flake.modules.common.discord-gui =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule = {
        packages = singleton pkgs.vesktop;
      };
    };
}
