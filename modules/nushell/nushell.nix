{ self, ... }:
{
  flake.modules.common.default = self.modules.common.nushell;
  flake.modules.common.nushell =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.strings) concatStringsSep;
    in
    {
      environment.shells = singleton <| getExe pkgs.nushell;

      hjemModule =
        {
          lib,
          osConfig,
          config,
          ...
        }:
        let
          nuLoadEnv = vars: ''
            load-env {${concatStringsSep ", " (mapAttrsToList (n: v: "${n}: \"${v}\"") vars)}}
          '';
        in
        {
          packages = [
            pkgs.bash
            pkgs.nushell
          ];

          files.".zshrc" = mkIf osConfig.nixpkgs.hostPlatform.isDarwin {
            # zsh
            text = mkAfter ''
              SHELL=${getExe pkgs.nushell} exec ${getExe pkgs.nushell} --config '${config.directory}/.config/nushell/config.nu'
            '';
          };

          xdg.config.files."nushell/config.nu".text =
            # nu
            ''
              ${
                lib.optionalString (osConfig.environment.variables != { })
                <| nuLoadEnv osConfig.environment.variables
              }
              $env.config.edit_mode = "helix"
              $env.config.buffer_editor = "${osConfig.environment.variables.EDITOR}"
              $env.config.show_banner = false
              $env.config.footer_mode = "auto"

              $env.config.use_kitty_protocol = true
              # $env.config.shell_integration.osc2 = true
              # $env.config.shell_integration.osc7 = true
              # $env.config.shell_integration.osc8 = true
              # $env.config.shell_integration.osc9_9 = true
              # $env.config.shell_integration.osc133 = true
              # $env.config.shell_integration.osc633 = true
              # $env.config.shell_integration.reset_application_mode = true

              $env.config.recursion_limit = 100
              $env.config.error_style = "nested"

              $env.config.ls.use_ls_colors = true
              $env.config.ls.clickable_links = true

              $env.config.rm.always_trash = false

              $env.config.table.mode = "single"
              $env.config.table.index_mode = "always"
              $env.config.table.show_empty = true

              $env.config.table.trim.methodology = "wrapping"
              $env.config.table.trim.wrapping_try_keep_words = true
              $env.config.table.trim.truncating_suffix = "..."

              $env.config.history.file_format = "sqlite"
              $env.config.history.max_size = 10000000
              $env.config.history.sync_on_enter = true

              $env.config.cursor_shape.emacs = "block"
              $env.config.cursor_shape.vi_insert = "line"
              $env.config.cursor_shape.vi_normal = "block"

              $env.config.float_precision = 2
              $env.config.use_ansi_coloring = "auto"

              $env.config.explore.help_banner = true
              $env.config.explore.exit_esc = true
              $env.config.explore.command_bar_text = "#C4C9C6"
              $env.config.explore.highlight.bg = "yellow"
              $env.config.explore.highlight.fg = "black"

              $env.config.explore.table.split_line = "#404040"
              $env.config.explore.table.cursor = true
              $env.config.explore.table.line_index = true
              $env.config.explore.table.line_shift = true
              $env.config.explore.table.line_head_top = true
              $env.config.explore.table.line_head_bottom = true
              $env.config.explore.table.show_head = true
              $env.config.explore.table.show_index = true

              $env.config.explore.config.cursor_color.bg = "yellow"
              $env.config.explore.config.cursor_color.fg = "black"

              $env.config.keybindings = [
                {
                  name: quit_shell
                  modifier: control
                  keycode: char_d
                  mode: [emacs, vi_insert, vi_normal, helix_insert, helix_normal]
                  event: null
                }
              ]
            '';
        };
    };
}
