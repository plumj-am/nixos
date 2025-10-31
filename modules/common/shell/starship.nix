{ lib, config, ... }:
let
  inherit (lib) disabled;
in
{
  home-manager.sharedModules = [{
    programs.starship = disabled {
    enableBashIntegration    = true;
    enableNushellIntegration = true;
    settings = {
      scan_timeout    = 100;
      command_timeout = 1000;

      format  = "[━](success_color)$status[━](success_color)[$username$hostname](hostname_color) $directory [━┫](success_color) \${custom.jj} [┣━](success_color) $cmd_duration$line_break$line_break";
      palette = "custom";

      palettes.custom = with config.theme.withHash; {
        username_color   = base07;
        hostname_color   = base0B;
        directory_color  = base0D;
        success_color    = base0D;
        error_color      = base08;
        branch_color     = base0C;
        status_highlight = base09;
        status_color     = base0C;
        state_color      = base01;
        duration_color   = base0A;
      };

      username.disabled    = true;
			username.show_always = true;
			username.format      = "$user";

      hostname.ssh_symbol = "s";
			hostname.ssh_only   = true;
			hostname.format     = "[$hostname]";

      status.disabled      = false;
			# success_symbol     = " "; # Uncomment to always show.
			status.format        = "[┫$status┣]($style)";
			status.failure_style = "error_color";
			status.success_style = "success_color";

      directory.format          = "[$path](duration_color)";
			directory.use_os_path_sep = false;
			directory.read_only       = "RO";

      character.success_symbol = "[┃](success_color)";
			character.error_symbol   = "[┃](success_color)";

			git_branch.disabled = true;
      git_branch.format   = "[\"$branch\"](purple)";

			git_status.disabled   = true;
      git_status.format     = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](status_highlight) ($ahead_behind$stashed)](status_color) ";
			git_status.conflicted = "​";
			git_status.untracked  = "​";
			git_status.modified   = "​";
			git_status.staged     = "​";
			git_status.renamed    = "​";
			git_status.deleted    = "​";
			git_status.stashed    = "≡";

			git_state.disabled = true;
      git_state.format   = "\\([$state( $progress_current/$progress_total)](state_color)\\)";

      git_metrics.disabled = true;
			git_metrics.format   = "[\\[](purple)[+$added](green)[-$deleted](red)[\\]](purple)";

      cmd_duration.format = "[$duration](duration_color)";

      nix_shell.symbol     = "❄️";
			nix_shell.format     = "[$symbol](branch_color)";
			nix_shell.impure_msg = "";
			nix_shell.pure_msg   = "";

			custom.jj.command        = "prompt";
			custom.jj.format         = "$output";
			custom.jj.ignore_timeout = true;
			custom.jj.shell          = ["starship-jj" "--ignore-working-copy" "starship"];
			custom.jj.use_stdin      = false;
			custom.jj.when           = true;
    };
    };
  }];
}
