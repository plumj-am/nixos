{
  flake.modules.nixos.rebuild =
    {
      pkgs,
      lib',
      ...
    }:
    let
      inherit (lib') mkDesktopEntry;
    in
    {
      environment.systemPackages = [
        pkgs.nh
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
