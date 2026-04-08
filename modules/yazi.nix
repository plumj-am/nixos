let
  yaziBase =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule = {
        packages = singleton pkgs.yazi;

        xdg.config.files."yazi/yazi.toml" = {
          generator = pkgs.writers.writeTOML "yazi-config.toml";
          value = {
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
    };
in
{
  flake.modules.nixos.yazi = yaziBase;
  flake.modules.darwin.yazi = yaziBase;
}
