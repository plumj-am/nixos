{ self, ... }:
{
  flake.modules.common.default = self.modules.common.herdr;
  flake.modules.common.herdr =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;

      plugins = {
        herdrJj = self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-jj;
      };

      herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./patches/herdr-longer-notification-timeout.patch ];
      });
    in
    {
      environment.systemPackages = [
        herdr

        self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-ide
      ];

      hjemModule =
        { osConfig, config, ... }:
        let
          inherit (osConfig) theme;

          worktreesDir = "${config.directory}/projects/herdr-worktrees";
        in
        {
          xdg.config.files = {
            "herdr/config.toml" = {
              source = pkgs.writers.writeTOML "herdr-config.toml" {
                onboarding = false;

                terminal.default_shell = "${getExe pkgs.nushell}";

                theme.name = theme.herdr;

                ui = {
                  pane_borders = "auto";
                  pane_outer_borders = false;
                  pane_gaps = false;
                  pane_scrollbars = false;

                  copy_on_select = true;
                  mouse_capture = true;

                  window_title = "{hostname}: {workspace}";

                  sidebar_width = 22;

                  agent_panel_sort = "priority";
                  status_indicators = "symbols";

                  tab_bar_position = "bottom";
                  tab_bar_right_separator = " · ";
                  tab_bar_right = [
                    { type = "zoom"; }
                    { type = "hostname"; }
                    {
                      type = "datetime";
                      format = "%H:%M";
                    }
                  ];

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
                      "$jj_change"
                      "$jj_status"
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

                worktrees.directory = worktreesDir;

                experimental.pane_history = true;

                keys = {
                  prefix = "ctrl+g";

                  focus_pane_left = "alt+h";
                  focus_pane_up = "alt+k";
                  focus_pane_down = "alt+j";
                  focus_pane_right = "alt+l";
                  zoom = "alt+f";

                  resize_mode = "alt+r";

                  workspace_picker = "prefix+ctrl+p";
                  navigate_workspace_down = "j";
                  navigate_workspace_up = "k";
                  navigate_pane_left = "";
                  navigate_pane_down = "";
                  navigate_pane_up = "";
                  navigate_pane_right = "";

                  previous_agent = "prefix+p";
                  next_agent = "prefix+n";

                  previous_workspace = "alt+shift+k";
                  next_workspace = "alt+shift+j";
                  goto = "prefix+shift+p";

                  split_horizontal = "prefix+ctrl+d";
                  split_vertical = "prefix+ctrl+r";
                  close_pane = "prefix+x";

                  swap_pane_left = "alt+ctrl+h";
                  swap_pane_up = "alt+ctrl+k";
                  swap_pane_down = "alt+ctrl+j";
                  swap_pane_right = "alt+ctrl+l";

                  switch_tab = "prefix+1..9";
                  switch_workspace = "prefix+alt+1..9";

                  move_tab_previous = "alt+ctrl+shift+h";
                  move_tab_next = "alt+ctrl+shift+l";

                  copy_mode = "prefix+s";

                  settings = "";

                  reload_config = "prefix+alt+shift+r";

                  command = osConfig.herdr.keys.command ++ [
                    {
                      key = "prefix+shift+a";
                      type = "plugin_action";
                      command = "olivergilan.herdr-jj.create";
                      description = "new jj workspace";
                    }
                    {
                      key = "prefix+a";
                      type = "plugin_action";
                      command = "olivergilan.herdr-jj.open";
                      description = "open jj workspace";
                    }
                    {
                      key = "prefix+alt+a";
                      type = "plugin_action";
                      command = "olivergilan.herdr-jj.remove";
                      description = "jj workspace: remove";
                    }
                  ];
                };
              };
            };

            # Minimal registry entry: herdr reloads actions and panes from the
            # manifest, so the stored entry needs only these fields.
            "herdr/plugins.json" = {
              source = pkgs.writers.writeJSON "herdr-plugins.json" [
                {
                  enabled = true;
                  plugin_id = "olivergilan.herdr-jj";
                  name = "Herdr JJ";
                  version = "0.1.0";
                  manifest_path = "${plugins.herdrJj}/herdr-plugin.toml";
                  plugin_root = toString plugins.herdrJj;
                }
              ];
            };

            "herdr/plugins/config/olivergilan.herdr-jj/config.toml" = {
              source = pkgs.writers.writeTOML "herdr-jj-config.toml" {
                # The plugin rejects a workspace_root that is not absolute.
                workspace_root = worktreesDir;
                create_bookmark = false;
                post_create = "try {direnv allow}; herdr-ide";
                status_remote = "origin";
              };
            };
          };
        };
    };
}
