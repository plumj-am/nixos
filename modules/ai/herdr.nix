{ self, ... }:
{
  flake.modules.common.ai-agents = self.modules.common.herdr;
  flake.modules.common.herdr =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (config) theme;

      # Prebuilt plugin root; herdr reads its manifest from the store path.
      jjWorkspacePlugin = self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-jj-workspace;
    in
    {
      environment.systemPackages =
        singleton
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;

      hjemModule =
        { config, ... }:
        {
          xdg.config.files."herdr/config.toml" = {
            source = pkgs.writers.writeTOML "herdr-config.toml" {
              onboarding = false;

              terminal.default_shell = "${getExe pkgs.nushell}";

              ui = {
                pane_borders = "off";
                pane_outer_borders = false;
                pane_gaps = false;
                pane_scrollbars = false;

                copy_on_select = true;
                mouse_capture = true;

                tab_bar_position = "bottom";
                window_title = "{hostname}: {workspace}";

                tab_bar_right_separator = " · ";
                tab_bar_right = [
                  { type = "zoom"; }
                  { type = "hostname"; }
                  {
                    type = "datetime";
                    format = "%H:%M";
                  }
                ];

                status_indicators = "symbols";

                toast = {
                  delivery = "herdr";
                  delay_seconds = 1;
                  herdr.position = "bottom-right";
                };

                sound.enabled = true;

                sidebar.spaces.rows = [
                  [
                    "state_icon"
                    "workspace"
                  ]
                  [
                    "branch"
                    "git_status"
                  ]
                ];
                sidebar.agents.rows = [
                  [
                    "state_icon"
                    "workspace"
                    "tab"
                  ]
                  [ "agent" ]
                ];
              };

              theme.name = theme.herdr;

              worktrees.directory = "${config.directory}/projects/herdr-worktrees";

              keys = {
                prefix = "ctrl+g";

                focus_pane_left = "alt+h";
                focus_pane_up = "alt+k";
                focus_pane_down = "alt+j";
                focus_pane_right = "alt+l";

                zoom = "alt+f";

                switch_tab = "prefix+1..9";

                cycle_pane_next = "alt+n";
                cycle_pane_previous = "alt+p";

                swap_pane_left = "alt+shift+h";
                swap_pane_up = "alt+shift+k";
                swap_pane_down = "alt+shift+j";
                swap_pane_right = "alt+shift+l";

                split_horizontal = "prefix+d";

                close_pane = "prefix+x";

                move_tab_previous = "prefix+h";
                move_tab_next = "prefix+l";

                copy_mode = "prefix+alt+s";

                workspace_picker = "prefix+alt+p";

                resize_pane_left = "prefix+alt+h";
                resize_pane_up = "prefix+alt+k";
                resize_pane_down = "prefix+alt+j";
                resize_pane_right = "prefix+alt+l";

                command = [
                  {
                    key = "prefix+j";
                    type = "pane";
                    command = "${getExe pkgs.jjui}";
                    description = "jjui";
                  }
                  {
                    key = "prefix+alt+d";
                    type = "pane";
                    command = "${getExe pkgs.hunk} --watch";
                    description = "hunk watch";
                  }
                  # README chords minus prefix+d, which split_horizontal owns.
                  {
                    key = "prefix+a";
                    type = "plugin_action";
                    command = "expnn.jj-workspace.new-tab";
                    description = "jj workspace (tab)";
                  }
                  {
                    key = "prefix+shift+a";
                    type = "plugin_action";
                    command = "expnn.jj-workspace.new";
                    description = "jj workspace";
                  }
                  {
                    key = "prefix+alt+a";
                    type = "plugin_action";
                    command = "expnn.jj-workspace.remove";
                    description = "jj workspace: remove";
                  }
                ];
              };
            };
          };

          # Minimal registry entry: herdr reloads actions and panes from the
          # manifest, so the stored entry needs only these fields.
          xdg.config.files."herdr/plugins.json" = {
            source = pkgs.writers.writeJSON "herdr-plugins.json" [
              {
                plugin_id = "expnn.jj-workspace";
                name = "jj workspaces";
                version = "0.5.0";
                manifest_path = "${jjWorkspacePlugin}/herdr-plugin.toml";
                plugin_root = toString jjWorkspacePlugin;
                enabled = true;
              }
            ];
          };

          xdg.config.files."herdr/plugins/config/expnn.jj-workspace/config.toml" = {
            source = pkgs.writers.writeTOML "herdr-jj-workspace-config.toml" {
              # Absolute path: the herdr server PATH is minimal.
              jj.command = "${getExe pkgs.jujutsu}";
              jj.workspace_root = "${config.directory}/projects/herdr-worktrees";

              # The plugin defaults to opencode, which this config installs
              # as `opencode2`. Use omp instead.
              agent.command = "omp";
            };
          };
        };
    };
}
