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
      inherit (lib') mkDesktopEntry mkHaskellScript;
    in
    {
      environment.systemPackages = [
        pkgs.nh
        pkgs.nix-output-monitor

        # (mkHaskellScript "rebuild-hs" {
        #   path = ../Rebuild.hs;
        #   deps = singleton "typed-process";
        # })
      ];

      hjem.extraModules = singleton (
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
        }
      );
    };
}
