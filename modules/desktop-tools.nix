{
  flake.modules.nixos.colour-picker =
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
        pkgs.hyprpicker

        (mkDesktopEntry {
          name = "Colour-Picker";
          exec = "hyprpicker --format=hex --autocopy";
        })
      ];
    };
}
