{ pkgs, lib, config, ... }: let
  inherit (lib) mkIf;
in mkIf config.isDesktopNotWsl {
  environment.systemPackages = [
    pkgs.hyprpicker
  ];

  home-manager.sharedModules = [{
    xdg.desktopEntries.hyprpicker = {
      name     = "Colour Picker";
      icon     = "image-x-generic";
      exec     = "hyprpicker --format=hex --autocopy";
      terminal = false;
    };
  }];
}
