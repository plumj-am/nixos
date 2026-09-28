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
            const TL_COMMAND = "hx"
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

            def run-in [pane: string, cmd: string] {
              ${herdr} pane run $pane $cmd | complete | ignore
            }

            def main [
              --cwd: string = "." # working directory for the new panes
              --pane: string      # the pane to build in; defaults to the focused one
            ]: nothing -> string {
              # A default cannot run a command, so resolve the focused pane here.
              let tl_pane = (if $pane == null {
                ${herdr} pane current | from json | get result.pane.pane_id
              } else {
                $pane
              })

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
