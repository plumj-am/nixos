let
  shellBase =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.options) mkOption;
      inherit (lib.types) attrsOf str;
      inherit (lib.meta) getExe;
    in
    {
      config.environment.shells = singleton <| getExe pkgs.nushell;

      options.shellAliases = mkOption {
        type = attrsOf str;
        default = { };
        description = "Additional shell aliases to be merged with defaults";
      };

      config.hjem.extraModules = singleton (
        {
          lib,
          osConfig,
          config,
          ...
        }:
        let
          inherit (osConfig) theme;
          inherit (lib.strings) readFile concatStringsSep;
          inherit (lib.meta) getExe;
          inherit (lib.attrsets) mapAttrsToList;

          nuLoadEnv = vars: ''
            load-env {${concatStringsSep ", " (mapAttrsToList (n: v: "${n}: \"${v}\"") vars)}}
          '';

          defaultAliases = {
            mp = "mprocs";

            todo = "hx ${config.directory}/notes/todo.md";
            notes = "hx ${config.directory}/notes";
            random = "hx ${config.directory}/notes/random.md";

            rm = "rm --recursive --verbose";
            cp = "cp --recursive --verbose --progress";
            mv = "mv --verbose";
            mk = "mkdir";

            ls = "eza";
            sl = "eza";
            ll = "eza -la";
            la = "eza -a";
            lsa = "eza -a";
            lsl = "eza -l -a";

            tree = "eza --tree --git-ignore --group-directories-first";

            git-graph = ''git log --graph --full-history --pretty=format:"%h%  %d%x20%s"'';

            fj = "fj --host https://git.plumj.am";

            oops = "nix run nixpkgs#sqlite -- ${config.xdg.config.directory}/nushell/history.sqlite3 'DELETE FROM history WHERE rowid IN (SELECT rowid FROM history ORDER BY rowid DESC LIMIT 5);'";

            cat = "${getExe pkgs.bat} --theme ${theme.bat}";
            less = "${getExe pkgs.bat} --plain";

            mosh = "mosh --no-init";

            dc = "discordo";

            ns = "niri-session";

            h = "hx";
            e = "hx"; # editor

            j = "jj";
            lj = "lazyjj";
            ju = "jjui";

            codex = "codex resume --ask-for-approval untrusted";
            oc = "opencode --continue";

            rebuild = "${config.directory}/nixos/rebuild.nu";

            nu-config-reference = "nu -c 'config nu --doc | nu-highlight | bat'";
          };

          zoxideNushellIntegration = # nu
            ''
              source ${
                pkgs.runCommand "zoxide-init-nu" { } ''${getExe pkgs.zoxide} init nushell --cmd=cd >> "$out"''
              }
            '';

          aliases = defaultAliases // osConfig.shellAliases;
        in
        {
          packages = [
            pkgs.bash
            pkgs.carapace
            pkgs.direnv
            pkgs.fish
            pkgs.inshellisense
            pkgs.nushell
            pkgs.zoxide
            pkgs.zsh
          ];

          xdg.config.files."direnv/lib/nix-direnv.sh".source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

          xdg.config.files."nushell/config.nu".text =
            # nu
            ''
              ${
                lib.optionalString (osConfig.environment.variables != { })
                <| nuLoadEnv osConfig.environment.variables
              }
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: val: "alias ${name} = ${val}") aliases)}
              $env.config.edit_mode = "vi"
              $env.config.buffer_editor = "${osConfig.environment.variables.EDITOR}"
              $env.config.show_banner = false
              $env.config.footer_mode = "auto"
              $env.config.use_kitty_protocol = true

              $env.config.recursion_limit = 100
              $env.config.error_style = "nested"

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
                {||
                  if (which direnv | is-empty) { return }

                  direnv export json | from json | default {} | load-env
                }
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

              ${zoxideNushellIntegration}

              source $"($nu.cache-dir)/carapace.nu"
              source $"($nu.cache-dir)/jj.nu"
            '';

          xdg.config.files."nushell/env.nu".text =
            with theme.withHash;
            #nu
            ''
              			use std/config ${theme.nushell}
              			$env.config.color_config = (${theme.nushell})

              			$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense,clap,jj,nu"
              			mkdir $"($nu.cache-dir)"
              			carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

              			jj util completion nushell | save --force $"($nu.cache-dir)/jj.nu"

              			# let carapace_completer = {|spans: list<string>|
                	# 		# If the current command is an alias, get it's expansion.
                 #      let expanded_alias = (scope aliases | where name == $spans.0 | get -i 0 | get -i expansion)

                 #      # Overwrite.
                 #      let spans = (if $expanded_alias != null  {
                 #          # put the first word of the expanded alias first in the span
                 #          $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
                 #      } else { $spans })

                 #      carapace $spans.0 nushell ...$spans
                 #      | from json
                 #      | if ($in | default [] | any {|| $in.display | str starts-with "ERR"}) { null } else { $in }
                 #    }

              			$env.LS_COLORS = (${pkgs.vivid}/bin/vivid generate ${theme.vivid})

              			let theme_json = $"${config.directory}/nixos/modules/theme.json"
              			if ($theme_json | path exists) {
              				let theme = (open $theme_json)
              				$env.THEME_MODE = $theme.mode
              				$env.THEME_SCHEME = $theme.scheme
              			} else {
              				$env.THEME_MODE = "${theme.variant}"
              				$env.THEME_SCHEME = "${theme.colorScheme}"
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
              		        $"(ansi '${base0E}') ⟶  (ansi rst)(ansi '${base0B}')($subpath)(ansi rst)"
              		      }
              			      $"($jj_root | path basename)($subpath)"
              			    } else {
              			      let pwd = if ($pwd | str starts-with ${config.directory}) {
              			        "~" | path join ($pwd | path relative-to ${config.directory})
              	      } else { $pwd }

              	      $pwd
              	    }

              				let directory = $"(ansi '${base0A}')($dir)(ansi rst)"

              				let jj_info = if (which jj | is-not-empty) {
              					try {
              						let jj_output = (jj --quiet --color always --ignore-working-copy log --no-graph --revisions @ --template '
              							separate(
              								" ",
              								bookmarks.join(", "),
              								if(empty, label("empty", "(empty)")),
              								coalesce(
              									surround("\"", "\"",
              										if(
              											description.first_line().substr(0, 26).starts_with(description.first_line()),
              											description.first_line().substr(0, 26),
              											description.first_line().substr(0, 25) ++ "…"
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

              						# Only show parent bookmark if current change has no bookmarks.
              						let jj_has_bookmark = (jj --quiet --color always log --no-graph --revisions @ --template 'bookmarks.len() > 0' err> /dev/null | str trim) == "true"
              						let jj_parent = if not $jj_has_bookmark {
              							(jj --quiet --color always --ignore-working-copy log --no-graph --revisions 'heads(::@ & bookmarks())' --template 'bookmarks ++ "\n"' err> /dev/null | lines | str join ",")
              						} else { "" }

              						let jj_parent_display = if ($jj_parent | is-not-empty) {
              							$"tug ← ($jj_parent)"
              						} else { "" }

              						let combined = if ($jj_parent_display | is-not-empty) and ($jj_output | is-not-empty) {
              							$" ($jj_parent_display) ($jj_output)"
              						} else if ($jj_parent_display | is-not-empty) {
              							$" ($jj_parent_display)"
              						} else if ($jj_output | is-not-empty) {
              							$" ($jj_output)"
              						} else { "" }
              						$combined
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
        }
      );
    };

  shellExtraDarwin =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkAfter;
      inherit (lib.meta) getExe;
    in
    {
      hjem.extraModules = singleton (
        { config, ... }:
        {
          xdg.config.files."zsh/.zshrc" = {
            text =
              # zsh
              mkAfter ''
                SHELL=${getExe pkgs.nushell} exec ${getExe pkgs.nushell} --config '${config.directory}/.config/nushell/config.nu'
              '';
          };

        }
      );

    };

in
{
  flake.modules.nixos.shell = shellBase;
  flake.modules.darwin.shell = {
    imports = [
      shellBase
      shellExtraDarwin
    ];
  };
}
