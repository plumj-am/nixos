{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-prompt;
  flake.modules.common.nushell-prompt =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (config) theme;
    in
    {
      hjemModule =
        { config, ... }:
        {
          xdg.config.files."nushell/config.nu".text =
            with theme.withHash; # nu
            "source ${pkgs.writeText "nushell-prompt.nu" ''
              use std/config ${theme.nushell}
              $env.config.color_config = (${theme.nushell})

              mkdir $"($nu.cache-dir)"

              $env.LS_COLORS = (${pkgs.vivid}/bin/vivid generate ${theme.vivid})

              def prompt [--transient --right]: nothing -> string {
                let bar = $"(ansi '${base0D}')(ansi attr_bold)━(ansi rst)"

                let exit_code = $env.LAST_EXIT_CODE

                let status = if not ($exit_code == 0) or $transient {
                  $"(ansi '${base0D}')┫(ansi rst)(if $exit_code == 0 { ansi '${base0D}' } else { ansi '${base08}' })($exit_code)(ansi rst)(ansi '${base0D}')┣(ansi rst)"
                } else {
                  ($bar)($bar)
                }

                let host = if ($env.SSH_CONNECTION? | is-not-empty) {
                  $" (ansi '${base0B}')(hostname)(ansi rst)"
                } else { "" }

                let jj_root = try {
                  jj workspace root err> /dev/null
                } catch { "" }

                let pwd = pwd | path expand

                let directory = if ($jj_root | is-not-empty) {
                  let subpath = $pwd | path relative-to $jj_root
                  let subpath = if ($subpath | is-not-empty) {
                    $"(ansi '${base0E}') ⟶ (ansi rst)(ansi '${base0B}')($subpath)(ansi rst)"
                  }
                    $"($jj_root | path basename)($subpath)"
                  } else {
                    let pwd = if ($pwd | str starts-with ${config.directory}) {
                      "~" | path join ($pwd | path relative-to ${config.directory})
                    } else { $pwd }
                  $pwd
                }

                let in_bwrap = $env | try { get IN_BWRAP; " (bwrap)" } catch { "" }

                let directory = $"(ansi '${base0A}')($directory)(ansi rst)(ansi '${base0B}')($in_bwrap)(ansi rst)"

                let jj_output = try {
                    jj --quiet --color always --ignore-working-copy log --no-graph --revisions @ --template '
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
                if(self.contained_in("private()"), label("private", "(private)")),
                if(conflict, label("conflict", "(conflict)")),
                if(divergent, label("divergent prefix", "(divergent)")),
                if(hidden, label("hidden prefix", "(hidden)")),
                if(immutable, label("immutable", "(immutable)")),
                )
                ' err> /dev/null | str trim
                } catch {
                  ""
                }

                let cmd_duration = ($env.CMD_DURATION_MS | into int) * 1ms
                let cmd_duration = if $cmd_duration <= 2sec {
                  ""
                } else {
                  let cmd_duration = if $cmd_duration >= 60sec {
                    $cmd_duration | format duration min
                  } else {
                    $cmd_duration | format duration sec
                  }
                  $" (ansi '${base0A}')($cmd_duration)"
                }

                let left_prompt = [
                  $status
                  $host
                  " "
                  $directory
                  (char nl)
                ] | str join

                let right_prompt = [
                  (if ($cmd_duration | is-not-empty) {
                    [
                      $cmd_duration
                      " "
                      $bar
                      $bar
                      " "
                    ] | str join
                  })
                  (if ($jj_output | is-not-empty) {
                    [
                      (ansi rst)
                      $jj_output
                      " "
                      $bar
                      $bar
                    ] | str join
                  })
                ] | str join

                if $right {
                  $right_prompt
                } else {
                  $left_prompt
                }
              }

              $env.PROMPT_COMMAND                 = {|| prompt }
              $env.PROMPT_COMMAND_RIGHT           = {|| prompt --right }
              $env.TRANSIENT_PROMPT_COMMAND       = {|| prompt --transient }
              $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| prompt --right --transient }

              $env.PROMPT_INDICATOR                     = " "
              $env.PROMPT_INDICATOR_VI_NORMAL           = $env.PROMPT_INDICATOR
              $env.PROMPT_INDICATOR_VI_INSERT           = $env.PROMPT_INDICATOR
              $env.PROMPT_MULTILINE_INDICATOR           = $env.PROMPT_INDICATOR
              $env.TRANSIENT_PROMPT_INDICATOR           = $env.PROMPT_INDICATOR
              $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = $env.PROMPT_INDICATOR
              $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = $env.PROMPT_INDICATOR
              $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = $env.PROMPT_INDICATOR
            ''}";
        };
    };
}
