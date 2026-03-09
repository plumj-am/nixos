{
  flake.modules.nixos.rebuild =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.myLib) mkDesktopEntry;
    in
    {
      environment.systemPackages = [
        pkgs.nh
        pkgs.nix-output-monitor
      ];

      hjem.extraModules = singleton (
        { config, ... }:
        {
          packages = singleton (mkDesktopEntry {
            name = "Rebuild";
            exec = "${config.directory}/nixos/rebuild.nu";
          });
        }
      );
    };
}
