{ config, lib, ... }:
let
	inherit (lib) enabled;
in
{
  home-manager.sharedModules = [{
    programs.nushell = enabled {
    shellAliases = {
      cat = "bat";

      ls  = "eza";
      sl  = "eza";
      ll  = "eza -la";
      la  = "eza -a";
      lsa = "eza -a";
      lsl = "eza -l -a";

      v   = "vim";
      vi  = "vim";
      nv  = "nvim";
      nvi = "nvim";

      claude = "claude --continue";

      m  = "moon";
      mp = "mprocs";
      ko = "kondo";

			# git
      g   = "git";
      gi  = "git";
      gti = "git";
      gt  = "git";

			# jujutsu
			j   = "jj";
			lj  = "lazyjj";

			mosh = "mosh --no-init";

      rebuild  = "~/nixos-config/rebuild.nu";
      rollback = "~/nixos-config/rollback.nu";
      # for some reason this doesn't work and is called every time I open a new shell
      # upgrade  = "sudo nix-store --verify --check-contents --repair ; sudo nix flake update --flake ~/nixos-config ; sudo nixos-rebuild switch --flake ~/nixos-config#nixos-wsl";

      tt = "toggle-theme";

      td = "hx ~/notes/todo.md";

      cdr = "cd (git rev-parse --show-toplevel | str trim)";
      cdn = "cd ~/nixos-config/dotfiles/nvim";
      cdc = "cd ~/nixos-config";
      cdp = "cd ~/projects";
      cdu = "cd ~/nixos-config/modules/common/shell";

      rm = "rm --recursive --verbose";
      cp = "cp --recursive --verbose --progress";
      mv = "mv --verbose";
      mk = "mkdir";

      tree = "eza --tree --git-ignore --group-directories-first";

      # steam-run for dynamically linked executables
      moon  = "steam-run moon";
      proto = "steam-run proto";
      bun   = "steam-run bun";
      bunx  = "steam-run bunx";
      npx   = "steam-run npx";

    };
    settings = {
      edit_mode     = "vi";
      buffer_editor = config.environment.variables.EDITOR;
      show_banner   = false;
      footer_mode   = "auto";

      recursion_limit = 100;
      error_style     = "fancy";

      completions.algorithm      = "substring";
			completions.sort           = "smart";
			completions.case_sensitive = false;
			completions.quick          = true;
			completions.partial        = true;
			completions.use_ls_colors  = true;

      ls.use_ls_colors   = true;
      ls.clickable_links = true;

      rm.always_trash = false;

      keybindings = [
        {
          name     = "quit_shell";
          modifier = "control";
          keycode  = "char_d";
          mode     = [ "emacs" "vi_insert" "vi_normal" ];
          event    = null;
        }
      ];

			table.mode       = "compact";
			table.index_mode = "always";
			table.show_empty = true;

			table.trim.methodology             = "wrapping";
			table.trim.wrapping_try_keep_words = true;
			table.trim.truncating_suffix       = "...";

			explore.help_banner           = true;
			explore.exit_esc              = true;
			explore.command_bar_text      = "#C4C9C6";
			explore.status_bar_background = {};
			explore.highlight.bg          = "yellow";
			explore.highlight.fg          = "black";
			explore.status                = {};
			explore.try                   = {};

			explore.table.split_line       = "#404040";
			explore.table.cursor           = true;
			explore.table.line_index       = true;
			explore.table.line_shift       = true;
			explore.table.line_head_top    = true;
			explore.table.line_head_bottom = true;
			explore.table.show_head        = true;
			explore.table.show_index       = true;

			explore.config.cursor_color.bg = "yellow";
			explore.config.cursor_color.fg = "black";

      history.file_format   = "sqlite";
			history.max_size      = 10000000;
			history.sync_on_enter = true;

      filesize = {};

      cursor_shape.emacs     = "block";
			cursor_shape.vi_insert = "block";
			cursor_shape.vi_normal = "block";

      float_precision   = 2;
      use_ansi_coloring = "auto";

      hooks.env_change.PWD = [ ''{ |before, after| zellij-update-tabname }'' ];

      hooks.display_output = "if (term size).columns >= 100 { table -e } else { table }";

			hooks.pre_prompt     = [
				''
					if not (which direnv | is-empty) {
						direnv export json | from json | default {} | load-env
						$env.PATH = ($env.PATH | split row (char env_sep))
					}
				''
			];
    };

    extraConfig = ''
      ${builtins.readFile ./menus.nu}
      ${builtins.readFile ./functions.nu}
      ${builtins.readFile ./theme.nu}
    '';

    envFile.text = ''
			use std/config ${config.theme.nushell}
			$env.config.color_config = (${config.theme.nushell})

			$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense,clap"
			$env.LS_COLORS = (vivid generate ${config.theme.vivid})
    '';
    };
  }];
}
