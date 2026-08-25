{ self, ... }:
{
  flake.modules.common.default = self.modules.common.rebuild;
  flake.modules.common.rebuild =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.nh
      ];

      hjem.extraModule =
        { lib, config, ... }:
        let
          inherit (lib.lists) singleton;
        in
        {
          packages =
            singleton
            <| pkgs.makeDesktopItem {
              desktopName = "Rebuild";
              name = "Rebuild";
              exec = "${config.directory}/nixos/rebuild.nu";
              terminal = false;
            };
        };
    };
}
