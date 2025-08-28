{ lib, config, ... }:
let
  inherit (lib) enabled;
in
{
  programs.starship = enabled {
    enableBashIntegration = true;
    enableNushellIntegration = true;
    settings = {
      scan_timeout = 100;
      command_timeout = 1000;
      format = "[┏━](success_color)$status[━](success_color) $directory [━┫](success_color) $git_branch$git_state$git_status$git_metrics [┣━━┫](success_color) \${custom.jj} [┣━](success_color) $cmd_duration$line_break$character";
      palette = config.theme.starship;

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
        format = "[$user]($style)";
        style_user = "username_color";
      };

      hostname = {
        ssh_symbol = "s";
        format = "[\\[$hostname\\]](hostname_color)";
      };

      status = {
        disabled = false;
        # success_symbol = " "; # to always show
        format = "[┫$status┣]($style)";
        failure_style = "error_color";
        success_style = "success_color";
      };

      directory = {
        format = "[$path](directory_color)";
        use_os_path_sep = false;
        read_only = "RO";
      };

      character = {
        success_symbol = "[┃](success_color)";
        error_symbol = "[┃](success_color)";
      };

      git_branch.format = "[\"$branch\"](purple)";

      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](status_highlight) ($ahead_behind$stashed)](status_color) ";
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "≡";
      };

      git_state.format = "\\([$state( $progress_current/$progress_total)](state_color)\\)";

      git_metrics = {
        disabled = false;
        format = "[\\[](purple)[+$added](green)[-$deleted](red)[\\]](purple)";
      };

      cmd_duration.format = "[$duration](duration_color)";

      nix_shell = {
        symbol = "❄️";
        format = "[$symbol](branch_color)";
        impure_msg = "";
        pure_msg = "";
      };

			custom.jj = {
				command        = "prompt";
				format         = "$output";
				ignore_timeout = true;
				shell          = ["starship-jj" "--ignore-working-copy" "starship"];
				use_stdin      = false;
				when           = true;
			};
    };
  };
}
