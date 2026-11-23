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
        mapAttrsToList (name: value: ''${name}: "${value}"'') theme.withHash
      );

      jjTemplate = # python
        ''
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
        '';
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

                def paint [color: string, text: string]: nothing -> string {
                  $"(ansi $color)($text)(ansi reset)"
                }

                def bar [color: string]: nothing -> string {
                  $"(ansi $color)(ansi attr_bold)━━(ansi reset)"
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
                  jj-refresh
                }]

                def jj-root []: nothing -> string {
                  mut dir = $env.PWD
                  mut root = ""
                  loop {
                    if ($dir | path join ".jj" | path exists) {
                      $root = $dir
                      break
                    }
                    let parent = ($dir | path dirname)
                    if $parent == $dir { break }
                    $dir = $parent
                  }
                  $root
                }

                # `--ignore-working-copy` output only changes with the operation
                # store, so one spawn per new operation is enough; typing and
                # plain shell commands reuse the cached right prompt.
                def jj-log []: nothing -> string {
                  try {
                    jj --quiet --color always --ignore-working-copy log --no-graph --revisions @ --template r###'${jjTemplate}'### err> /dev/null | str trim
                  } catch {
                    ""
                  }
                }

                def --env jj-refresh []: nothing -> nothing {
                  let root = (jj-root)
                  let key = if ($root | is-empty) {
                    ""
                  } else {
                    let heads = ($root | path join ".jj/repo/op_heads/heads")
                    if ($heads | path exists) {
                      try { ls $heads | get name | sort | str join "," } catch { "" }
                    } else {
                      ""
                    }
                  }
                  let cached = $env.JJ_PROMPT? | default { root: "", key: "", output: "" }

                  if ($root == $cached.root) and ($key | is-not-empty) and ($key == $cached.key) {
                    return
                  }

                  $env.JJ_PROMPT = {
                    root: $root
                    key: $key
                    output: (if ($root | is-empty) { "" } else { jj-log })
                  }
                }

                def prompt [--transient --right]: nothing -> string {
                  let state = if ($env.JJ_PROMPT? | is-empty) {
                    { root: (jj-root), key: "", output: (jj-log) }
                  } else {
                    $env.JJ_PROMPT
                  }

                  let colors = $env.THEME_COLORS
                  let bar = bar $colors.base0D

                  if $right {
                    if ($state.output | is-empty) { return "" }
                    return ([$bar (char sp) (ansi rst) $state.output (char sp) $bar] | str join)
                  }

                  let exit_code = $ans | get --optional exit_code | default 0

                  let status = if not ($exit_code == 0) or $transient {
                    let status_color = if $exit_code == 0 { $colors.base0D } else { $colors.base08 }
                    $"(paint $colors.base0D "┫")(paint $status_color $"($exit_code)")(paint $colors.base0D "┣")"
                  } else {
                    $bar
                  }

                  let host = if ($env.SSH_CONNECTION? | is-not-empty) {
                    $" (paint $colors.base0B (sys host | get hostname))"
                  } else { "" }

                  let pwd = $env.PWD

                  let directory = if ($state.root | is-not-empty) {
                    let subpath = $pwd | path relative-to $state.root
                    let subpath = if ($subpath | is-not-empty) {
                      $"(paint $colors.base0E "⟶") (paint $colors.base0B $subpath)"
                    }
                      $"($state.root | path basename)($subpath)"
                    } else {
                      let pwd = if ($pwd | str starts-with ${config.directory}) {
                        "~" | path join ($pwd | path relative-to ${config.directory})
                      } else { $pwd }
                    $pwd
                  }

                  let directory = paint $colors.base0A $directory

                  [
                    $status
                    $host
                    (char sp)
                    $directory
                    (char nl)
                  ] | str join
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
