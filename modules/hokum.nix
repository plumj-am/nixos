{ self, ... }:
{
  flake.nixosModules.desktop = self.nixosModules.hokum;
  flake.nixosModules.hokum =
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

      hokum = inputs.hokum.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Built-ins: soft, crisp, capsule, ribbon, terminal, bubble, signal, pill.
      styleId = "crisp";

      mkAppearance =
        variant: colours: # kdl
        ''
          tokens "${variant}" {
              fill "${colours.base00}"
              text "${colours.base06}"
              muted "${colours.base05}"
              faint "${colours.base04}"
              accent "${colours.base0D}"
          }
        '';
    in
    {
      environment.systemPackages = [
        hokum
        # Hokum's default sound names (message-new-instant, dialog-warning) come
        # from here.
        pkgs.sound-theme-freedesktop
      ];
      services.dbus.packages = singleton hokum;

      systemd.packages = singleton hokum;
      systemd.user.services.hokum.wantedBy = singleton "graphical-session.target";

      hjemModule = {
        xdg.config.files."hokum/config.kdl" = {
          type = "copy"; # Settings window tries to write this, so good to have while tweaking.
          text = # kdl
            ''
              theme "${styleId}"

              // Palette from modules/theme.nix. The config merges on top of the
              // selected theme, so these tokens recolour whichever theme the
              // settings window picks; only the look is overridden, not the look's
              // template, rules or motion.
              tokens {
                  font "sans"
                  font-size ${toString theme.font.size.normal}
              }

              ${mkAppearance "dark" theme.palettes.dark}
              ${mkAppearance "light" theme.palettes.light}

              behaviour {
                  position "top-right"
                  stay 10
                  show-at-most 5
                  pause-on-hover #true
                  do-not-disturb #false
                  appearance "system"
                  clock "auto"
                  check-for-updates #false
                  // Native sounds: freedesktop theme names, played with pw-play.
                  sound #true
              }

              modules {
                  sound #true
                  bluetooth #true
                  osd #true
                  brightness #true
                  bluetooth-notifications #true
              }
            '';
        };
      };
    };
}
