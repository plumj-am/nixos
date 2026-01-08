{
  config.flake.modules.homeModules.nh =
    { pkgs, ... }:
    let
      packages = [
        pkgs.nh
        pkgs.nix-output-monitor
      ];
    in
    {
      inherit packages;
    };
}
