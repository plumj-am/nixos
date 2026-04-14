{
  flake.modules.common.rio =
    {
      pkgs,
      lib,
      lib',
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib') mkDesktopEntry;
      inherit (config) theme;
    in
    {

      hjem.extraModule = {
        packages = [
          pkgs.rio

          (mkDesktopEntry {
            name = "Zellij-Rio";
            exec = "rio --command ${getExe pkgs.zellij}";
          })
        ];

        xdg.config.files."rio/config.toml" = {
          generator = pkgs.writers.writeTOML "rio-config.toml";
          value = {
            shell.program = getExe pkgs.nushell;
            font.family = theme.font.mono.name;
            renderer = {
              performance = "High";
              backend = "GL";
              target_fps = 280;
            };
          };
        };
      };
    };
}
