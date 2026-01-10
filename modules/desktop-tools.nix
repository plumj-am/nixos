{
  config.flake.modules.nixos.desktop-tools =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.thunar
        pkgs.tumbler

        pkgs.hyprpicker

        (pkgs.writeTextFile {
          name = "colour-picker";
          destination = "/share/applications/colour-picker.desktop";
          text = ''
            [Desktop Entry]
            Name=Colour Picker
            Icon=image-x-generic
            Exec=hyprpicker --format=hex --autocopy
            Terminal=false
          '';
        })
      ];
    };
}
