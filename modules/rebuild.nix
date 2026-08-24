{ self, ... }:
{
  flake.modules.common.default = self.modules.common.rebuild;
  flake.modules.common.rebuild =
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
}
