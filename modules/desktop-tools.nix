{
  flake.modules.nixos.colour-picker =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (config.myLib) mkDesktopEntry;
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
