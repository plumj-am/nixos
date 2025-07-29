{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    settings = {
      format = " $username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$character";
      
      username = {
        disabled = false;
        show_always = true;
        format = "[$user]($style) ";
        style_user = "#2d2d2d";
      };
      
      hostname = {
        ssh_symbol = "s";
        style = "#1f5f99";
        format = "[\\[$hostname\\]]($style) ";
      };
      
      directory = {
        format = "[$path]($style) ";
        style = "#7c3aed";
        use_os_path_sep = false;
        read_only = "RO";
      };
      
      character = {
        success_symbol = "[❯](#059669)";
        error_symbol = "[❯](#dc2626)";
      };
      
      git_branch = {
        format = "[@$branch]($style)";
        style = "#374151";
      };
      
      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](#b45309) ($ahead_behind$stashed)]($style)";
        style = "#1e40af";
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
        style = "#6b7280";
      };
      
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "#dc2626";
      };
    };
  };
}
