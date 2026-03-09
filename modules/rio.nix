let
  # TODO: Configuration.
  # No point configuring yet because it still doesn't work for some reason.
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

      toml = pkgs.formats.toml { };

      rioConfig = {
        shell.program = "nu";
        renderer = {
          performance = "High";
          backend = "GL";
          target_fps = 280;
        };
      };
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

        xdg.config.files."rio/config.toml".source = toml.generate "rio-config.toml" rioConfig;
      };
    };
in
{
  flake.modules.nixos.rio = rioBase;
  flake.modules.darwin.rio = rioBase;
}
