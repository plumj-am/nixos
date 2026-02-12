let
  ashellBase =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config) theme;

      toml = pkgs.formats.toml { };

      settings = with theme.withHash; {
        renderer = "gl";

        layer = "Bottom";
        enable_esc_key = true;

        modules = {
          shutdown_cmd = "systemctl poweroff";
          suspend_cmd = "hyprlock --quiet & systemctl suspend";
          hibernate_cmd = "hyprlock --quiet & systemctl hibernate";
          reboot_cmd = "systemctl reboot";
          logout_cmd = "hyprlock --quiet --grace 60";

          left = [ ];
          center = [ "WindowTitle" ];
          right = [
            "Tray"
            [
              "SystemInfo"
            ]
            [
              "Privacy"
              "Settings"
            ]
            [
              "Tempo"
            ]
          ];
        };

        indicators = [
          "Audio"
          "Network"
          "PeripheralBattery"
          "Battery"
        ];

        appearance = {
          font_name = theme.font.sans.name;
          style = "Solid";

          background_color = {
            base = base00;
            strong = base00;
            weak = base01;
          };
          primary_color.base = base01;
          secondary_color.base = base01;
          success_color.base = base0B;
          danger_color.base = base08;
          text_color.base = base07;
        };

        tempo = {
          weather_location = "Current";
          clock_format = "%Y-%m-%d | %H:%M";
        };

        system_info = {
          indicators = [
            "Cpu"
            "Memory"
            {
              "Disk" = "/";
              Name = "";
            }
            "Temperature"
          ];
          temperature.sensor = "coretemp Package id 0";
        };
      };
    in
    {
      hjem.extraModules = singleton {
        packages = singleton inputs.ashell.packages.${pkgs.stdenv.hostPlatform.system}.default;

        xdg.config.files."ashell/config.toml".source = toml.generate "ashell.toml" settings;
      };
    };
in
{
  flake-file.inputs = {
    ashell = {
      url = "github:malpenzibo/ashell";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.ashell = ashellBase;
}
