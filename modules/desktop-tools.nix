{
  flake.modules.nixos.colour-picker =
    {
      pkgs,
      lib,
      lib',
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib') mkDesktopEntry;
    in
    {
      environment.systemPackages = [
        pkgs.eyedropper

        (mkDesktopEntry {
          name = "Colour-Picker";
          exec = getExe pkgs.eyedropper;
        })
      ];
    };
}
