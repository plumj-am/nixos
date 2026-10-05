{ self, ... }:
{
  flake.modules.common.default = self.modules.common.tuicr;
  flake.modules.common.tuicr =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkDefault;
    in
    {
      environment.systemPackages = singleton pkgs.tuicr;

      hjemModule = {
        xdg.config.files = {
          "tuicr/config.toml" = {
            generator = pkgs.writers.writeTOML "tuicr-config.toml";
            value = {
              appearance = "system";
              theme_dark = "gruvbox-dark";
              theme_light = "gruvbox-light";

              diff_view = "side-by-side";
              ignore_whitespace = true;
              compact_folders = true;
              show_pr_checks = true;
              pr_comments_visibility = "all";
              comment_vim = false;

              scroll_offset = 4;
              relative_line_numbers = false;

              leader = "  ";
              diff_watch_interval_ms = 5000;

              editor = config.environment.variables.EDITOR;
            };
          };
        };
      };
    };
}
