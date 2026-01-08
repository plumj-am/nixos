{
  config.flake.modules.nixosModules.hyprpicker =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.hyprpicker
      ];

      # TODO
      # xdg.desktopEntries.hyprpicker = {
      #   name     = "Colour Picker";
      #   icon     = "image-x-generic";
      #   exec     = "hyprpicker --format=hex --autocopy";
      #   terminal = false;
      # };
    };
}
