let
  rioBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.myLib) mkDesktopEntry;
      inherit (lib.lists) singleton;
    in
    {

      hjem.extraModules = singleton {
        packages = [
          pkgs.rio

          (mkDesktopEntry {
            name = "Zellij-Rio";
            exec = "rio -c ${pkgs.zellij}/bin/zellij";
          })
        ];

        xdg.config.files."rio/config.toml" = {
          generator = pkgs.writers.writeTOML "rio-config.toml";
          value = {
            shell.program = "nu";
            renderer = {
              performance = "High";
              backend = "GL";
              target_fps = 280;
            };
          };
        };
      };
    };
in
{
  flake.modules.nixos.rio = rioBase;
  flake.modules.darwin.rio = rioBase;
}
