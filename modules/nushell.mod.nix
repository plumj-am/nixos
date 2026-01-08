{
  config.flake.modules.homeModules.nushell =
    { pkgs, config, lib, ... }:
    let
      inherit (lib.strings) readFile;
    in
    {
      programs.nushell = {
        enable = true;

        aliases = {
          m = "moon";
          mp = "mprocs";
          ko = "kondo";

          td = "hx ${config.directory}/notes/todo.md";
          notes = "hx ${config.directory}/notes";
          random = "hx ${config.directory}/notes/random.md";

          rm = "rm --recursive --verbose";
          cp = "cp --recursive --verbose --progress";
          mv = "mv --verbose";
          mk = "mkdir";

          tree = "eza --tree --git-ignore --group-directories-first";

          swarm = "mprocs claude claude claude claude claude";

          fj = "fj --host https://git.plumj.am";

          oops = "nix run nixpkgs#sqlite -- ${config.directory}/.config/nushell/history.sqlite3 'DELETE FROM history WHERE rowid IN (SELECT rowid FROM history ORDER BY rowid DESC LIMIT 5);'";
        };

        extraConfig =
        # nu
        ''
          $env.config.edit_mode = "vi"
          $env.config.buffer_editor = "hx"
          $env.config.show_banner = false
          $env.config.footer_mode = "auto"

          $env.config.recursion_limit = 100
          $env.config.error_style = "fancy"

          $env.config.completions.algorithm = "substring"
          $env.config.completions.sort = "smart"
          $env.config.completions.case_sensitive = false
          $env.config.completions.quick = true
          $env.config.completions.partial = true
          $env.config.completions.use_ls_colors = true

          $env.config.ls.use_ls_colors = true
          $env.config.ls.clickable_links = true

          $env.config.rm.always_trash = false

          $env.config.table.mode = "compact"
          $env.config.table.index_mode = "always"
          $env.config.table.show_empty = true

          $env.config.table.trim.methodology = "wrapping"
          $env.config.table.trim.wrapping_try_keep_words = true
          $env.config.table.trim.truncating_suffix = "..."

          $env.config.history.file_format = "sqlite"
          $env.config.history.max_size = 10000000
          $env.config.history.sync_on_enter = true

          $env.config.cursor_shape.emacs = "block"
          $env.config.cursor_shape.vi_insert = "line"
          $env.config.cursor_shape.vi_normal = "block"

          $env.config.float_precision = 2
          $env.config.use_ansi_coloring = "auto"

          $env.config.explore.help_banner = true
          $env.config.explore.exit_esc = true
          $env.config.explore.command_bar_text = "#C4C9C6"
          $env.config.explore.highlight.bg = "yellow"
          $env.config.explore.highlight.fg = "black"

          $env.config.explore.table.split_line = "#404040"
          $env.config.explore.table.cursor = true
          $env.config.explore.table.line_index = true
          $env.config.explore.table.line_shift = true
          $env.config.explore.table.line_head_top = true
          $env.config.explore.table.line_head_bottom = true
          $env.config.explore.table.show_head = true
          $env.config.explore.table.show_index = true

          $env.config.explore.config.cursor_color.bg = "yellow"
          $env.config.explore.config.cursor_color.fg = "black"

          $env.config.keybindings = [
            {
              name: quit_shell
              modifier: control
              keycode: char_d
              mode: emacs
              event: null
            }
            {
              name: quit_shell
              modifier: control
              keycode: char_d
              mode: vi_insert
              event: null
            }
            {
              name: quit_shell
              modifier: control
              keycode: char_d
              mode: vi_normal
              event: null
            }
          ]

          $env.config.hooks.env_change.PWD = [
            { |before, after| zellij-update-tabname }
          ]

          $env.config.hooks.display_output = {
            if (term size).columns >= 100  { tee { table --expand | print } } | try { if $in != null { $env.last = $in } }
          }

          $env.config.hooks.pre_prompt = [
            {
              if not (which direnv | is-empty) {
                direnv export json | from json | default {} | load-env
                $env.PATH = ($env.PATH | split row (char env_sep))
              }
            }
          ]

          ${readFile ./nushell.menus.nu}
          ${readFile ./nushell.functions.nu}
        '';

        envFile = with config.theme.withHash;
        #nu
        ''
    			use std/config ${config.theme.nushell}
    			$env.config.color_config = (${config.theme.nushell})

    			$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense,clap"
    			$env.LS_COLORS = (${pkgs.vivid}/bin/vivid generate ${config.theme.vivid})

    			let theme_json = $"($env.HOME)/nixos/modules/theme/theme.json"
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
    					$" (ansi '${base0B}')(hostname)(ansi rst)"
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
    											description.first_line().substr(0, 22).starts_with(description.first_line()),
    											description.first_line().substr(0, 22),
    											description.first_line().substr(0, 21) ++ "…"
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
    };
}
