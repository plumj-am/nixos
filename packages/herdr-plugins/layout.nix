{ inputs, ... }: {
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;

      herdr = getExe inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
    in
    {
      packages.herdr-ide =
        pkgs.writers.writeNuBin "herdr-ide" # nu
          ''
            # Build an IDE-like layout in herdr.
            # +-----------------------+
            # | 68x75        | 32x75  |
            # |              |        |
            # +-----------------------+
            # | 50x25     | 50x25     |
            # +-----------------------+

            const TOP_RATIO = 0.75
            const LEFT_RATIO = 0.68
            const BOTTOM_RATIO = 0.5
            const TL_COMMAND = ""
            const BL_COMMAND = ""
            const TR_COMMAND = "omp"
            const BR_COMMAND = ""

            # Split $target and return the new pane id.
            def split-pane [
              target: string
              direction: string
              ratio: float
              cwd: string
            ] {
              let result = (${herdr} pane split $target
                --direction $direction
                --ratio $ratio
                --cwd $cwd
                --no-focus | complete)

              if $result.exit_code != 0 {
                error make { msg: $"herdr pane split failed: ($result.stderr | str trim)" }
              }

              $result.stdout | from json | get result.pane.pane_id
            }

            # Resolve the directory for the new panes.
            def resolve-cwd [requested: string, pane_cwd: string] {
              let path = (($pane_cwd | path join $requested) | path expand)

              if ($path | path type) != "dir" {
                error make { msg: $"not a directory: ($path)" }
              }

              $path
            }

            def run-in [pane: string, cmd: string] {
              ${herdr} pane run $pane $cmd | complete | ignore
            }

            def main [
              --cwd: string       # directory for the new panes; defaults to the pane directory
              --pane: string      # the pane to build in; defaults to the focused one
            ]: nothing -> string {
              # A default cannot run a command, so read the target pane here.
              let info = (
                if $pane == null {
                  ${herdr} pane current | from json | get result.pane
                } else {
                  ${herdr} pane get $pane | from json | get result.pane
                }
              )

              let tl_pane = $info.pane_id

              # The pane reports an absolute directory. Use it when the caller
              # asks for none.
              let cwd = resolve-cwd (
                if $cwd == null { $info.cwd? } else { $cwd }
              ) ($info.cwd? | default $env.PWD)

              # Halve by height first: the root becomes the top row, the new pane the
              # bottom row, and each row still spans the full width.
              let bl_pane = split-pane $tl_pane down $TOP_RATIO $cwd

              # Each row now divides at its own ratio, independently.
              let tr_pane = split-pane $tl_pane right $LEFT_RATIO $cwd

              let br_pane = split-pane $bl_pane right $BOTTOM_RATIO $cwd

              run-in $tl_pane $TL_COMMAND
              run-in $tr_pane $TR_COMMAND
              run-in $bl_pane $BL_COMMAND
              run-in $br_pane $BR_COMMAND

              print $"tl: ($tl_pane)  tr: ($tr_pane)  bl: ($bl_pane)  br: ($br_pane)"

              $tl_pane
            }
          '';
    };
}
