{ self, ... }:
{
  flake.modules.common.zyouz =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.generators) toZON zon;
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;

      # Can't get nushell to work directly for some reason.
      nu = [
        (getExe pkgs.bash)
        "-c"
        "nu"
      ];

      mkKeymap = key: action: {
        inherit action key;
      };
    in
    {
      hjem.extraModule = {
        packages = singleton self.packages.${pkgs.stdenv.hostPlatform.system}.zyouz;

        xdg.config.files."zyouz/config.zon" = {
          generator = toZON;
          value = {
            pane_gap = 0;
            exit_on_focus_change = true;

            prefix_key = "ctrl-g";
            keymaps = [
              (mkKeymap "ctrl-q" "quit")
              (mkKeymap "ctrl-h" "focus_left")
              (mkKeymap "ctrl-j" "focus_down")
              (mkKeymap "ctrl-k" "focus_up")
              (mkKeymap "ctrl-l" "focus_right")
            ];

            layouts = [
              {
                name = "default";
                root.command = nu;
              }
              {
                name = "ide";
                root = {
                  direction = zon.enum "vertical";
                  children = [
                    {
                      direction = zon.enum "horizontal";
                      size.percent = 70;
                      children = [
                        {
                          command = nu;
                          size.percent = 70;
                          mouse = zon.enum "passthrough";
                          name = "editor";
                        }
                        {
                          command = nu;
                          mouse = zon.enum "passthrough";
                          name = "slop";
                        }
                      ];
                    }
                    {
                      direction = zon.enum "horizontal";
                      children = [
                        {
                          command = nu;
                          name = "nu";
                        }
                        {
                          command = nu;
                          name = "nu";
                        }
                      ];
                    }
                  ];
                };
              }
            ];
          };
        };
      };
    };
}
