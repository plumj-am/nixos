{
  flake.modules.common.tmux =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.meta) getExe;
    in
    {
      programs.tmux = {
        enable = true;

        secureSocket = false;

        plugins = [
          pkgs.tmuxPlugins.gruvbox
        ];
      };

      hjem.extraModule.files.".tmux.conf".text =
        # bash
        ''
          set -s buffer-limit 100
          set -sg escape-time 0
          set -s exit-unattached off
          set -s set-clipboard on
          set -s focus-events on
          set -g prefix C-g
          set -g base-index 1
          set -g renumber-windows on
          set -g history-limit 50000
          set -g status-keys vi
          set -g bell-action any
          set -g default-shell ${getExe pkgs.nushell}
          set -g default-command ""
          set -g default-terminal "tmux-256color"
          set -ga terminal-overrides ",*256col*:Tc"
          set -g destroy-unattached off
          set -g detach-on-destroy on
          set -g repeat-time 500
          set -g word-separators " -_@"
          set -g remain-on-exit off
          set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
          set -g set-titles on
          set -g set-titles-string "#S:#I:#W - \"#T\" #{session_alerts}"
          set -g display-time 1500
          set -g display-panes-active-colour red
          set -g display-panes-colour blue
          set -g display-panes-time 1000
          set -g message-limit 20
          set -g lock-after-time 0
          set -g lock-command "lock -np"
          set -g assume-paste-time 1
          set -g mouse on
          set -g status on
          set -g status-position bottom
          set -g status-interval 15
          set -g status-justify left
          set -g status-style "bg=green,fg=black"
          set -g status-left-style "default"
          set -g status-right-style "default"
          set -g message-style "bg=yellow,fg=black"
          set -g message-command-style "bg=black,fg=yellow"
          set -g status-left  "[#S] "
          set -g status-right '"#T" %H:%M %d-%b-%Y'
          set -g status-left-length  10
          set -g status-right-length 40

          setw -g window-status-format         " #I:#W#F "
          setw -g window-status-current-format " #I:#W#F "
          setw -g window-status-separator " "
          setw -g window-status-style          "default"
          setw -g window-status-current-style  "reverse"
          setw -g window-status-last-style     "default"
          setw -g window-status-activity-style "blink"
          setw -g window-status-bell-style     "bold"
          setw -g pane-base-index 0
          setw -g mode-keys vi
          setw -g mode-style "reverse"
          setw -g monitor-activity off
          setw -g monitor-silence 0

          set -g pane-border-style        "fg=default"
          set -g pane-active-border-style "fg=green"
          set -g pane-border-lines single
          set -g pane-border-status off
          set -g pane-border-format "#{pane_index} #{pane_title}"
          set -g visual-activity off
          set -g visual-bell off
          set -g visual-silence off
          setw -g allow-rename on
          setw -g automatic-rename on
          setw -g automatic-rename-format "#{pane_current_command}"
          setw -g alternate-screen on
          setw -g remain-on-exit off
          setw -g synchronize-panes off
          setw -g xterm-keys off
          setw -g wrap-search on
          setw -g aggressive-resize off
          setw -g clock-mode-colour green
          setw -g clock-mode-style  24
          setw -g main-pane-width  80
          setw -g main-pane-height 24
          setw -g other-pane-height 0
          setw -g other-pane-width  0

          bind r source-file ~/.tmux.conf \; display "Config reloaded!"
          bind | split-window -h -c "#{pane_current_path}"
          unbind '"'
          bind - split-window -v -c "#{pane_current_path}"
          unbind %
          bind o choose-tree -Zs

          bind -n M-enter resize-pane -Z     # default binding; listed for documentation
          bind -n M-h select-pane -L
          bind -n M-j select-pane -D
          bind -n M-k select-pane -U
          bind -n M-l select-pane -R

          unbind z

          set -g @plugin 'tmux-plugins/tpm'
          set -g @plugin 'egel/tmux-gruvbox'
          set -g @tmux-gruvbox '${if !config.theme.isDark then "light" else "dark"}'

          # must be at end
          run '~/.tmux/plugins/tpm/tpm'
        '';
    };
}
