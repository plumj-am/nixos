{
  flake.modules.hjem.yazi =
    { lib, isDesktop, ... }:
    let
      inherit (lib.modules) mkIf;
    in
    mkIf isDesktop {
      rum.programs.yazi = {
        enable = true;

        settings = {
          mgr = {
            ratio = [
              2
              2
              4
            ];
            show_hidden = true;
            show_symlink = false;
            scrolloff = 5;
          };

          preview = {
            wrap = "no";
            tab_size = 3;
            image_delay = 0;
            image_filter = "lanczos3";
            image_quality = 90;
          };

          input.cursor_blink = false;
        };
      };
    };
}
