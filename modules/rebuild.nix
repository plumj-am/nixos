{
  flake.modules.nixos.rebuild =
    { pkgs, config, ... }:
    let
      inherit (config.myLib) mkDesktopEntry;
    in
    {
      environment.systemPackages = [
        pkgs.nh
        pkgs.nix-output-monitor

        (mkDesktopEntry {
          name = "Rebuild";
          exec = "/home/jam/nixos/rebuild.nu";
        })
      ];
    };
}
