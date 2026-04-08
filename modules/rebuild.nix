{
  flake.modules.nixos.rebuild =
    {
      pkgs,
      lib,
      lib',
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib') mkDesktopEntry mkDirtyHaskellScript;
    in
    {
      environment.systemPackages = [
        pkgs.nh
        pkgs.nix-output-monitor

        (mkDirtyHaskellScript "rebuild-hs" {
          path = ../Rebuild.hs;
          deps = singleton "typed-process";
        })
      ];

      hjem.extraModule =
        { config, ... }:
        {
          packages = [
            (mkDesktopEntry {
              name = "Rebuild";
              exec = "${config.directory}/nixos/rebuild.nu";
            })
            (mkDesktopEntry {
              name = "Rebuild-hs";
              exec = "rebuild-hs --local";
            })
          ];
        };
    };

  flake.modules.darwin.rebuild =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.nh
        pkgs.nix-output-monitor
      ];
    };
}
