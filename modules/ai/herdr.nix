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
                ];
              };
            };
          };
        };
    };
}
