{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-completions;
  flake.modules.common.nushell-completions =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
    in
    {
      environment.sessionVariables.CARAPACE_BRIDGES = "inshellisense,carapace,zsh,fish,bash";

      environment.systemPackages = [
        pkgs.bash
        pkgs.carapace
        pkgs.inshellisense
        pkgs.zsh
        pkgs.fish
      ];

      hjemModule = {
        xdg.config.files."nushell/config.nu".text = # nu
          ''
            # TODO: remove below once fixed in Tern!!
            # TODO: remove below once fixed in Tern!!

            # Tern starts each pane from a login-environment capture instead of
            # its own environment. The capture runs `printenv PATH` in a
            # scrubbed login shell; when it fails, tern falls back to the
            # libc default (/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin),
            # which on NixOS holds only bash, sh and env. Every profile
            # directory is then gone and aliases like ls -> eza stop
            # resolving. Seed PATH first: carapace.nu below reads $env.PATH
            # unguarded, and a missing column is an error, not an empty
            # string, so the whole config would die before any later block.
            # TODO: remove once fixed in Tern!!
            let profile_dirs = [
              "/run/wrappers/bin"
              $"/etc/profiles/per-user/($env.USER)/bin"
              "/nix/var/nix/profiles/default/bin"
              "/run/current-system/sw/bin"
            ]
            $env.PATH = (
              ($env.PATH? | default [])
              | append $profile_dirs
              | uniq
            )

            # TODO: remove above once fixed in Tern!!
            # TODO: remove above once fixed in Tern!!

            $env.config.completions.algorithm = "substring"
            $env.config.completions.sort = "smart"
            $env.config.completions.case_sensitive = false
            $env.config.completions.quick = true
            $env.config.completions.partial = true
            $env.config.completions.use_ls_colors = true

            let menus = [
              {
                name: completion_menu
                only_buffer_difference: false
                marker: "| "
                type: {
                  layout: ide
                  min_completion_width: 0
                  max_completion_width: 150
                  max_completion_height: 25
                  padding: 0
                  border: false
                  cursor_offset: 0
                  description_mode: prefer_right
                  min_description_width: 0
                  max_description_width: 50
                  max_description_height: 10
                  description_offset: 1
                  correct_cursor_pos: true
                }
                style: {
                  text: green
                  selected_text: green_reverse
                  description_text: yellow
                  match_text: {attr: u}
                  selected_match_text: {attr: ur}
                }
              }
              {
                name: history_menu
                only_buffer_difference: true
                marker: "? "
                type: {layout: list, page_size: 10}
                style: {text: green, selected_text: green_reverse}
              }
              {
                name: help_menu
                only_buffer_difference: true
                marker: "? "
                type: {
                  layout: description
                  columns: 4
                  col_width: 20
                  col_padding: 2
                  selection_rows: 4
                  description_rows: 10
                }
                style: {text: green, selected_text: green_reverse, description_text: yellow}
              }
              {
                name: commands_menu
                only_buffer_difference: false
                marker: "# "
                type: {
                  layout: columnar
                  columns: 4
                  col_width: 20
                  col_padding: 2
                }
                style: {text: green, selected_text: green_reverse, description_text: yellow}
                source: {|buffer, position|
                  $nu.scope.commands | where name =~ $buffer | each {|it| {value: $it.name description: $it.usage} }
                }
              }
              {
                name: vars_menu
                only_buffer_difference: true
                marker: "# "
                type: {layout: list, page_size: 10}
                style: {text: green, selected_text: green_reverse, description_text: yellow}
                source: {|buffer, position|
                  $nu.scope.vars | where name =~ $buffer | sort-by name | each {|it| {value: $it.name description: $it.type} }
                }
              }
              {
                name: commands_with_description
                only_buffer_difference: true
                marker: "# "
                type: {
                  layout: description
                  columns: 4
                  col_width: 20
                  col_padding: 2
                  selection_rows: 4
                  description_rows: 10
                }
                style: {text: green, selected_text: green_reverse, description_text: yellow}
                source: {|buffer, position|
                  $nu.scope.commands | where name =~ $buffer | each {|it| {value: $it.name description: $it.usage} }
                }
              }
            ]

            $env.config.menus = $env.config.menus
            | where name not-in ($menus | get name)
            | append $menus

            source ${
              pkgs.runCommand "carapace.nu" { } ''
                ${getExe pkgs.carapace} _carapace nushell > $out
              ''
            }
          '';
      };
    };
}
