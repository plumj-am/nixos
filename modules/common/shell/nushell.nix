{ pkgs, config, lib, ... }: let
	inherit (lib) enabled;
in {
  home-manager.sharedModules = [
    (homeArgs: {
      programs.nushell = enabled {
      shellAliases = config.environment.shellAliases // {
        m  = "moon";
        mp = "mprocs";
        ko = "kondo";

        td     = "hx ${homeArgs.config.home.homeDirectory}/notes/todo.md";
        notes  = "hx ${homeArgs.config.home.homeDirectory}/notes";
        random = "hx ${homeArgs.config.home.homeDirectory}/notes/random.md";

        rm = "rm --recursive --verbose";
        cp = "cp --recursive --verbose --progress";
        mv = "mv --verbose";
        mk = "mkdir";

        tree = "eza --tree --git-ignore --group-directories-first";

        # Open current repository in GitHub.
        repo = /* nu */ ''
          if (^git rev-parse --is-inside-work-tree | complete | get exit_code) == 0 {
            start (^git remote get-url origin | str replace "git@github.com:" "https://github.com/")
          } else {
            print "Not in a Git directory."
            ${pkgs.libnotify}/bin/notify-send "Repo" "Failed to open repository. Not in a Git directory."
            exit 1
          }
        '';


        # Deletes the last 5 entries from the nushell history sqlite database.
        oops = "nix run nixpkgs#sqlite -- ${homeArgs.config.home.homeDirectory}/.config/nushell/history.sqlite3 'DELETE FROM history WHERE rowid IN (SELECT rowid FROM history ORDER BY rowid DESC LIMIT 5);'";


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

      hooks.env_change.PWD = [
        /* nu */ ''{ |before, after| zellij-update-tabname }''
      ];

      hooks.display_output = /* nu */ ''
        if (term size).columns >= 100  { tee { table --expand | print } } | try { if $in != null { $env.last = $in } }
      '';

			hooks.pre_prompt     = [
				/* nu */ ''
					if not (which direnv | is-empty) {
						direnv export json | from json | default {} | load-env
						$env.PATH = ($env.PATH | split row (char env_sep))
					}
				''
			];
    };

    extraConfig = /* nu */ ''
      ${builtins.readFile ./menus.nu}
      ${builtins.readFile ./functions.nu}

			# $env.config.hooks.command_not_found = {|c|
			# 	try {
			# 		print $"(ansi purple)[FALLBACK](ansi rst) Command not found '($c)'"
			# 		print $"(ansi purple)[FALLBACK](ansi rst) Trying with comma."
			# 		let pkg = ($c | str trim)
			# 		let pkgs = (comma --print-packages ($pkg))
			# 		if ($pkgs | str downcase | str contains "no packages") { null }
			# 		comma --ask ($pkg)
			# 		null
			# 	} catch { null }
			# }
    '';

    envFile.text = with config.theme.withHash; /* nu */ ''
			# use std/config ${config.theme.nushell}
			# $env.config.color_config = (${config.theme.nushell})

			$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense,clap"
			$env.LS_COLORS = (${pkgs.vivid}/bin/vivid generate ${config.theme.vivid})

			# Load theme state from theme.json
			let theme_json = $"($env.HOME)/nixos/modules/common/theme/theme.json"
			if ($theme_json | path exists) {
				let theme = (open $theme_json)
				$env.THEME_MODE = $theme.mode
				$env.THEME_SCHEME = $theme.scheme
			} else {
				$env.THEME_MODE = "${config.theme.variant}"
				$env.THEME_SCHEME = "${config.theme.color_scheme}"
			}

			# Custom Nushell prompt.

			def prompt [--transient]: nothing -> string {
				let exit_code = $env.LAST_EXIT_CODE

				let status = if not ($exit_code == 0) or $transient {
					$"(ansi '${base0D}')┫(ansi rst)(if $exit_code == 0 { ansi '${base0D}' } else { ansi '${base08}' })($exit_code)(ansi rst)(ansi '${base0D}')┣(ansi rst)"
				} else {
					$"(ansi '${base0D}')━(ansi rst)"
				}

				let host = if ($env.SSH_CONNECTION? | is-not-empty) {
					$"(ansi '${base0B}')(hostname)(ansi rst)"
				} else { "" }

				let jj_root = try {
		      jj workspace root err> /dev/null
		    } catch { "" }

		    let pwd = pwd | path expand

		    let dir = if ($jj_root | is-not-empty) {
		      let subpath = $pwd | path relative-to $jj_root
		      let subpath = if ($subpath | is-not-empty) {
		        $"(ansi '${base0E}') ⟶ (ansi rst)(ansi '${base0B}')($subpath)(ansi rst)"
		      }
			      $"($jj_root | path basename)($subpath)"
			    } else {
			      let pwd = if ($pwd | str starts-with $env.HOME) {
			        "~" | path join ($pwd | path relative-to $env.HOME)
	      } else { $pwd }

	      $pwd
	    }

				let directory = $"(ansi '${base0A}')($dir)(ansi rst)"

				let jj_info = if (which jj | is-not-empty) {
					try {
						let jj_output = (^jj --quiet --color always --ignore-working-copy log --no-graph --revisions @ --template '
							separate(
								" ",
								bookmarks.join(", "),
								if(empty, label("empty", "(empty)")),
								coalesce(
									surround("\"", "\"",
										if(
											description.first_line().substr(0, 16).starts_with(description.first_line()),
											description.first_line().substr(0, 16),
											description.first_line().substr(0, 15) ++ "…"
								  	)
								  ),
									label(if(empty, "empty"), "")
								),
								change_id.shortest(),
								commit_id.shortest(),
								if(conflict, label("conflict", "(conflict)")),
								if(divergent, label("divergent prefix", "(divergent)")),
								if(hidden, label("hidden prefix", "(hidden)")),
								if(immutable, label("immutable", "(immutable)")),
							)
						' err> /dev/null | str trim)
						if ($jj_output | is-not-empty) {
							$" ($jj_output)"
						} else { "" }
					} catch { "" }
				} else { "" }

				let ms = ($env.CMD_DURATION_MS | into int)
				let duration = if $transient or $ms > 1000 {
					let secs = $ms / 1000 | math floor
					if $transient and $ms < 1000 {
						$" (ansi '${base0A}')($ms)ms"
					} else {
						$" (ansi '${base0A}')($secs)s"
					}
				} else { "" }

				let bar = $"(ansi '${base0D}')(ansi attr_bold)━(ansi rst)"

				let prompt_line = [
					(char nl)
					$bar
					$status
					$bar
					$host
					" "
					$directory
					" "
					(if ($jj_info | is-not-empty) {
						[
							$"(ansi '${base0D}')━┫(ansi rst)"
							$jj_info
							$" (ansi '${base0D}')┣━(ansi rst)"
						] | str join
					} else {
						[
							$bar
							$bar
							$bar
						] | str join
					})
					$duration
					(char nl)
				] | str join

				$prompt_line
			}

			# Set prompt
			$env.PROMPT_COMMAND                 = { || prompt }
			$env.PROMPT_COMMAND_RIGHT           = ""
			$env.TRANSIENT_PROMPT_COMMAND       = { || prompt --transient }
			$env.TRANSIENT_PROMPT_COMMAND_RIGHT = ""

			$env.PROMPT_INDICATOR                     = " "
			$env.PROMPT_INDICATOR_VI_NORMAL           = $env.PROMPT_INDICATOR
			$env.PROMPT_INDICATOR_VI_INSERT           = $env.PROMPT_INDICATOR
			$env.PROMPT_MULTILINE_INDICATOR           = $env.PROMPT_INDICATOR
			$env.TRANSIENT_PROMPT_INDICATOR           = $env.PROMPT_INDICATOR
			$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = $env.PROMPT_INDICATOR
			$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = $env.PROMPT_INDICATOR
			$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = $env.PROMPT_INDICATOR
    '';
    };
    })
  ];
}
