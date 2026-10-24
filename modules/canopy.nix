{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.canopy;
  flake.modules.nixos.canopy =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    let
      inherit (config) theme;

      font = {
        icons = theme.icons.name;
        mono = theme.font.mono.name;
        sans = theme.font.sans.name;

        icon_size = 15.0;
        mono_size = 13.0;
        sans_size = 15.0;

        dirs = [ ];
      };
    in
    {
      environment.systemPackages = with inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}; [
        canopy-canopy-bar
        canopy-canopy-launcher
      ];

      hjemModule = {
        xdg.config.files."canopy/bar.toml" = {
          generator = pkgs.writers.writeTOML "canopy-bar.toml";
          value = {
            inherit font;
            theme.mode = "system";

            bar = {
              namespace = "canopy-bar";

              height = 32;
              padding = 12;
              spacing = 8;
            };

            widgets = {
              left = [ ];
              center = [ "window" ];
              right = [
                "tray"
                "separator"
                "cpu"
                "ram"
                "disk"
                "network"
                "gpu"
                "battery"
                "separator"
                "clock"
              ];
            };

            widget.window.max_width = 300;

            widget.cpu.interval_ms = 2000;

            widget.ram.interval_ms = 2000;

            widget.disk = {
              interval_ms = 60000;
              path = "/";
            };

            widget.network = {
              interface_interval_ms = 30000;
              rate_interval_ms = 5000;
            };

            widget.gpu = {
              args = [
                "--query-gpu=utilization.gpu"
                "--format=csv,noheader,nounits"
              ];
              command = "nvidia-smi";
              interval_ms = 2000;
            };

            widget.battery = {
              critical = 10;
              low = 20;
            };

            widget.clock = {
              date_format = "%Y-%m-%d";
              time_format = "%H:%M";
            };
          };
        };

        xdg.config.files."canopy/launcher.toml" = {
          generator = pkgs.writers.writeTOML "canopy-launcher.toml";
          value = {
            inherit font;
            theme.mode = "system";

            window = {
              lines = 15;
              width_chars = 30;

              border_radius = 10;
              border_width = 1;

              horizontal_pad = 10;
              inner_pad = 0;
              vertical_pad = 8;
            };

            icons = {
              enabled = true;
              theme = "default";
            };

            search = {
              fields = [
                "name"
                "generic"
                "keywords"
              ];
              max_results = 50;
              frecency_half_life_days = 14;
              prompt = "> ";
              use_cache = true;
            };
          };
        };

        xdg.config.files."canopy/dark-theme.toml" = {
          generator = pkgs.writers.writeTOML "canopy-dark-theme.toml";
          value.colors = theme.palettes.dark;
        };
        xdg.config.files."canopy/light-theme.toml" = {
          generator = pkgs.writers.writeTOML "canopy-light-theme.toml";
          value.colors = theme.palettes.light;
        };
      };
    };
}
