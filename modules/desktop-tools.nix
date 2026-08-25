{
  flake.modules.nixos.colour-picker =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
    in
    {
      environment.systemPackages = [
        pkgs.eyedropper

        (pkgs.makeDesktopItem {
          desktopName = "Colour Picker";
          name = "Colour-Picker";
          exec = getExe pkgs.eyedropper;
          terminal = false;
        })
      ];
    };
}
