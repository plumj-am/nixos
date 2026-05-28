{
  flake.modules.common.zyouz =
    {
      inputs,
      pkgs,
      lib,
      lib',
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib') zon;
      inherit (lib'.generators) toZON;

      # zyouz flake uses pkgs.zig.hook (Zig 0.16) but source targets 0.15.x.
      # build.zig.zon uses enum syntax (0.15+) and std.heap.GeneralPurposeAllocator
      # was removed in 0.16. zig_0_15 has both and works.
      zyouzPackage = pkgs.stdenv.mkDerivation {
        pname = "zyouz";
        version = "0.3.0";
        src = inputs.zyouz;
        nativeBuildInputs = singleton pkgs.zig_0_15.hook;
        dontUseZigCheck = true;
        meta.mainProgram = "zyouz";
      };

      # Can't get nushell to work directly for some reason.
      nu = [
        (getExe pkgs.bash)
        "-c"
        "nu"
      ];

      mkKeymap = key: action: {
        inherit key action;
      };
    in
    {
      hjem.extraModule = {
        packages = singleton zyouzPackage;

        xdg.config.files."zyouz/config.zon" = {
          generator = toZON;
          value = {
            pane_gap = 0;

            prefix_key = "ctrl-g";
            keymaps = [
              (mkKeymap "ctrl-q" "quit")
              (mkKeymap "h" "focus_left")
              (mkKeymap "j" "focus_down")
              (mkKeymap "k" "focus_up")
              (mkKeymap "l" "focus_right")
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
