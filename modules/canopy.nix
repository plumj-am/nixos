{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.canopy;
  flake.modules.nixos.canopy =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe';
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
      environment.systemPackages =
        (with inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}; [
          canopy-bar
          # canopy-clipboard
          # canopy-control
          canopy-launcher
          # canopy-media
          # canopy-notify
        ])
        ++ [
          # Needed by canopy-control.
          pkgs.brightnessctl
          pkgs.bluez
          pkgs.bluez-tools
          pkgs.iproute2

          # Needed by canopy-notify.
          pkgs.libnotify
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
                # "notify"
                # "media"
                # "separator"
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
        xdg.config.files."canopy/notify.toml" = {
          generator = pkgs.writers.writeTOML "canopy-notify.toml";
          value = {
            max_rows = 8;
            relative_time = true;
            panel = {
              anchor = "top-right";
              margin = 40;
              width = 380;
              height = 480;
              padding = 12;
              radius = 10;
              border_width = 1;
            };
          };
        };

        xdg.config.files."canopy/media.toml" = {
          generator = pkgs.writers.writeTOML "canopy-media.toml";
          value = {
            show_album = true;
            panel = {
              anchor = "top-left";
              margin = 40;
              width = 360;
              height = 180;
              padding = 16;
              radius = 10;
              border_width = 1;
            };
          };
        };

        xdg.config.files."canopy/clipboard.toml" = {
          generator = pkgs.writers.writeTOML "canopy-clipboard.toml";
          value = {
            max_entries = 50;
            prompt = "";
            panel = {
              anchor = "bottom";
              margin = 0;
              width = 500;
              height = 440;
              padding = 12;
              radius = 10;
              border_width = 1;
            };
          };
        };

        xdg.config.files."canopy/control.toml" = {
          generator = pkgs.writers.writeTOML "canopy-control.toml";
          value = {
            panel = {
              anchor = "top-right";
              margin = 0;
              width = 360;
              height = 340;
              padding = 12;
              radius = 10;
              border_width = 1;
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

      # hjem relinks the generated configs above on every switch, so ask the bar
      # to re-read them once the user manifest has been applied.
      systemd.services."hjem-activate@".postStart = ''
        ${getExe' pkgs.procps "pkill"} --signal USR1 canopy-* || true
      '';
    };
}
