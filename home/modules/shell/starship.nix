{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    settings = {
      palette = "dark_theme";

      format = " $username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$line_break";

      palettes.light_theme = {
        username_color = "#2d2d2d";
        hostname_color = "#1f5f99";
        directory_color = "#7c3aed";
        success_color = "#059669";
        error_color = "#dc2626";
        branch_color = "#374151";
        status_highlight = "#b45309";
        status_color = "#1e40af";
        state_color = "#6b7280";
        duration_color = "#dc2626";
      };

      palettes.dark_theme = {
        username_color = "white";
        hostname_color = "green";
        directory_color = "blue";
        success_color = "blue";
        error_color = "red";
        branch_color = "cyan";
        status_highlight = "218";
        status_color = "cyan";
        state_color = "bright-black";
        duration_color = "yellow";
      };

      username = {
        disabled = false;
        show_always = true;
        format = "[$user]($style) ";
        style_user = "username_color";
      };

      hostname = {
        ssh_symbol = "s";
        style = "hostname_color";
        format = "[\\[$hostname\\]]($style) ";
      };

      directory = {
        format = "[$path]($style) ";
        style = "directory_color";
        use_os_path_sep = false;
        read_only = "RO";
      };

      character = {
        success_symbol = "[❯](success_color)";
        error_symbol = "[❯](error_color)";
      };

      git_branch = {
        format = "[@$branch]($style)";
        style = "branch_color";
      };

      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](status_highlight) ($ahead_behind$stashed)]($style)";
        style = "status_color";
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "≡";
      };

      git_state = {
        format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
        style = "state_color";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "duration_color";
      };
    };
  };
}
