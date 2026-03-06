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
      };
    };
in
{
  flake.modules.nixos.rio = rioBase;
  flake.modules.darwin.rio = rioBase;
}
