{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-prompt;
  flake.modules.common.nushell-prompt =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.meta) getExe;
      inherit (lib.strings) concatStringsSep;
      inherit (config) theme;

      fallbackColors = concatStringsSep "\n" (
        mapAttrsToList (name: value: "      ${name}: \"${value}\"") theme.withHash
      );
    in
    {
      hjemModule =
        { config, ... }:
        {
          xdg.config.files."nushell/config.nu".text = "source ${
            pkgs.writeText "nushell-prompt.nu" # nu
              ''
                use std/config [${theme.apps.nushell.dark} ${theme.apps.nushell.light}]

                mkdir $"($nu.cache-dir)"

                # `toggle-theme` switches to a specialisation, so a running shell
                # only learns about the new variant through `/etc/theme.json`
                # (see modules/theme.nix). Re-applying it before every prompt
                # keeps already open sessions in sync, without `exec nu`.
                const THEME_STATE = "/etc/theme.json"

                # Used before the first switch, and where specialisations do not
                # exist (the state file is NixOS only).
                const THEME_FALLBACK = {
                  mode: "${theme.variant}"
                  colors: {
                ${fallbackColors}
                  }
                }

                def theme-state []: nothing -> record {
                  if ($THEME_STATE | path exists) {
                    try { open $THEME_STATE } catch { { } }
                  } else {
                    { }
                  }
                }

                def --env apply-theme []: nothing -> nothing {
                  let state = (theme-state)
                  let dark = (($state.mode? | default $THEME_FALLBACK.mode) == "dark")

                  $env.THEME_MODE = (if $dark { "dark" } else { "light" })
                  $env.THEME_APPLIED = $state
                  $env.THEME_COLORS = ($THEME_FALLBACK.colors | merge ($state.colors? | default { }))
                  $env.THEME_BAT = (if $dark { "${theme.apps.bat.dark}" } else { "${theme.apps.bat.light}" })
                  $env.config.color_config = (if $dark {
                    ${theme.apps.nushell.dark}
                  } else {
                    ${theme.apps.nushell.light}
                  })
                  $env.LS_COLORS = (${getExe pkgs.vivid} generate (if $dark {
                    "${theme.apps.vivid.dark}"
                  } else {
                    "${theme.apps.vivid.light}"
                  }))
                }

                apply-theme

                $env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default []) ++ [{||
                  if (theme-state) != ($env.THEME_APPLIED? | default { }) { apply-theme }
                }]

                def prompt [--transient --right]: nothing -> string {
                  let colors = $env.THEME_COLORS

                  let bar = $"(ansi $colors.base0D)(ansi attr_bold)━(ansi rst)"

                  let exit_code = $env.LAST_EXIT_CODE

                  let status = if not ($exit_code == 0) or $transient {
                    $"(ansi $colors.base0D)┫(ansi rst)(if $exit_code == 0 { ansi $colors.base0D } else { ansi $colors.base08 })($exit_code)(ansi rst)(ansi $colors.base0D)┣(ansi rst)"
                  } else {
                    ($bar)($bar)
                  }

                  let host = if ($env.SSH_CONNECTION? | is-not-empty) {
                    $" (ansi $colors.base0B)(hostname)(ansi rst)"
                  } else { "" }

                  let jj_root = try {
                    jj workspace root err> /dev/null
                  } catch { "" }

                  let pwd = pwd | path expand

                  let directory = if ($jj_root | is-not-empty) {
                    let subpath = $pwd | path relative-to $jj_root
                    let subpath = if ($subpath | is-not-empty) {
                      $"(ansi $colors.base0E) ⟶ (ansi rst)(ansi $colors.base0B)($subpath)(ansi rst)"
                    }
                      $"($jj_root | path basename)($subpath)"
                    } else {
                      let pwd = if ($pwd | str starts-with ${config.directory}) {
                        "~" | path join ($pwd | path relative-to ${config.directory})
                      } else { $pwd }
                    $pwd
                  }

                  let in_bwrap = $env | try { get IN_BWRAP; " (bwrap)" } catch { "" }

                  let directory = $"(ansi $colors.base0A)($directory)(ansi rst)(ansi $colors.base0B)($in_bwrap)(ansi rst)"

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

                  let left_prompt = [
                    $status
                    $host
                    (char sp)
                    $directory
                    (char nl)
                  ] | str join

                  let right_prompt = [
                    (if ($jj_output | is-not-empty) {
                      [
                        $bar
                        $bar
                        (char sp)
                        (ansi rst)
                        $jj_output
                        (char sp)
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
              ''
          }";
        };
    };
}
