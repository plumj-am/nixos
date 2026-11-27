{ self, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (lib.attrsets) getAttr mapAttrs unionOfDisjoint;
      inherit (lib.meta) getExe;
      inherit (lib.strings) toJSON;
      inherit (lib.trivial) const;

      nom = getExe inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.nom-rs;
    in
    {
      # Credit for structure and some code: <https://github.com/RGBCube/ncc>
      #
      # Builds always run on the current machine. Remote targets only receive a
      # copy of the already built toplevel and the activation commands.
      packages.default =
        pkgs.writers.writeNuBin "rebuild" # nu
          ''
            const PROFILE = "/nix/var/nix/profiles/system"

            def class-of [host: string] {
              let known = r###'${
                self.nixosConfigurations or { }
                |> unionOfDisjoint self.darwinConfigurations or { }
                |> mapAttrs (const <| getAttr "class")
                |> toJSON
              }'### | from json

              if ($host not-in ($known | columns)) {
                error make $"unknown host ($host); known hosts: ($known | columns | str join ', ')"
              }

              $known | get $host
            }

            def is-local [host: string] {
              (sys host | get hostname) == $host
            }

            def resolve-target [target: string] {
              match ($target | is-empty) {
                true  => { sys host | get hostname }
                false => $target
              }
            }

            # Command prefix needed to run something as root on the target.
            def escalate [target: string, local: bool, tty: bool] {
              match [$local $tty] {
                [true _     ] if (^id --user | str trim) == "0" => [ ]
                [true _     ] => [ "sudo" ]
                [false true ] => [ "ssh" "-tt" $"root@($target)" ]
                [false false] => [ "ssh"       $"root@($target)" ]
                _             => { error make $"escalate: unhandled case local=($local) tty=($tty)" }
              }
            }

            # Runs a command as root on the target (locally via sudo, remotely
            # via ssh). Use --no-tty when capturing output.
            def --wrapped as-root [target: string --no-tty ...cmd: string] {
              let local = is-local $target

              let full = (escalate $target $local (not $no_tty)) ++ $cmd
              ^($full | first) ...($full | skip 1)
            }

            def get-active-theme [target: string] {
              let local = is-local $target

              match $local {
                true  => { open --raw /etc/theme.json }
                false => { ^ssh $"root@($target)" open --raw /etc/theme.json err> /dev/null }
              }
              | try {
                from json
                | get --optional mode
              }
              | default ""
            }

            def build [target: string, class: string, extra: list<string>] {

              let command = [
                "nix"
                "build"
                $"${self}#($class)Configurations.($target).config.system.build.toplevel"
                "--accept-flake-config"
                "--keep-going"
                "--no-link"
                "--print-out-paths"
                "--log-format" "internal-json"
                "-v"
                ...$extra
                "--builders" ""
              ]

              let out_file = mktemp --suffix ".toplevel"

              try {
                print $"building ($target) on (sys host | get hostname)..."

                ^($command | first) ...($command | skip 1) out> $out_file err>| ^${nom}
              } catch {|e|
                error make $"building ($target) failed: ($e.msg)"
              }

              let paths = open $out_file | lines
              rm $out_file

              if ($paths | is-empty) {
                error make $"nix build for ($target) returned no output path"
              }

              $paths | last
            }

            def copy [target: string, toplevel: string] {
              print $"copying ($toplevel) to ($target)..."
              nix copy --substitute-on-destination --no-check-sigs --to $"ssh-ng://root@($target)" $toplevel
            }

            # Resolves the specialisation path inside a built toplevel, mirroring
            # `nixos-rebuild --specialisation`.
            def resolve-theme [target: string, toplevel: string, specialisation: string] {
              let local = is-local $target

              if ($specialisation | is-empty) { return $toplevel }

              let candidate = $toplevel | path join "specialisation" $specialisation
              let exists = match $local {
                true  => { $candidate | path exists }
                false => { (^ssh $"root@($target)" "test" "-e" $candidate | complete | get exit_code) == 0 }
              }

              if not $exists {
                error make $"specialisation ($specialisation) not found in ($toplevel)"
              }

              $candidate
            }

            def show-diff [target: string, toplevel: string] {
              try { as-root $target ${getExe pkgs.dix} diff --min-size-delta 1 /run/current-system $toplevel }
            }

            def set-profile [target: string, toplevel: string] {
              as-root $target nix build --no-link --profile $PROFILE $toplevel
            }

            def activate [target: string, class: string, toplevel: string] {
              match $class {
                "darwin" => { as-root $target $"($toplevel)/activate" }
                "nixos"  => { as-root $target $"($toplevel)/bin/switch-to-configuration" switch }
                _        => { error make $"unsupported class ($class)" }
              }
            }

            def deploy [target: string, specialisation: string, extra: list<string>] {
              let class = class-of $target
              let local = is-local $target

              let theme = match ($specialisation | is-not-empty) {
                true  => $specialisation
                false => { get-active-theme $target }
              }

              let toplevel = build $target $class $extra

              if not $local {
                copy $target $toplevel
              }

              let activate_path = resolve-theme $target $toplevel $theme

              show-diff $target $toplevel
              set-profile $target $toplevel
              activate $target $class $activate_path

              print $"rebuild for ($target) succeeded."
            }

            def rollback [target: string, specialisation: string] {
              let class = class-of $target
              let local = is-local $target

              let current = as-root $target --no-tty readlink $PROFILE
              | str trim
              | split row "-"
              | get 1
              | into int

              let choices = $target
              | match $local {
                true => {
                  ls /nix/var/nix/profiles
                  | get name
                  | path basename
                }
                false => {
                  as-root $target --no-tty ^ls "-1" /nix/var/nix/profiles
                  | lines
                }
              }
              | where {(str starts-with "system-") and (str ends-with "-link") }
              | each {
                {
                  name: $in
                  generation: ($in | split row "-" | get 1 | into int)
                }
              }
              | sort-by generation --reverse
              | where generation != $current
              | each { $"system-($in.generation)-link" }

              if ($choices | is-empty) {
                error make $"no generation before system-($current)-link on ($target)"
              }

              let chosen = $choices | input list "Roll back to:"
              if ($chosen | is-empty) {
                error make "rollback cancelled"
              }

              let generation = $chosen
              | split row "-"
              | get 1

              let theme = match ($specialisation | is-not-empty) {
                true  => $specialisation
                false => { get-active-theme $target }
              }

              # Resolve first so a bad specialisation fails before anything changes.
              let activate_path = resolve-theme $target $"/nix/var/nix/profiles/($chosen)" $theme

              as-root $target nix-env --profile $PROFILE --switch-generation $generation
              activate $target $class $activate_path

              print $"($target) rolled back to generation ($generation)."
            }

            def main [] { help main }

            def --wrapped "main deploy" [
              target: string = ""                # Host to deploy (defaults to the current machine)
              --specialisation (-s): string = "" # Activate this specialisation instead of the base config
              ...rest: string                    # Extra arguments to pass to nix build
            ] {
              deploy (resolve-target $target) $specialisation $rest
            }

            def "main rollback" [
              target: string = ""                # Host to roll back (defaults to the current machine)
              --specialisation (-s): string = "" # Activate this specialisation instead of the base config
            ] {
              rollback (resolve-target $target) $specialisation
            }

            def "main theme" [
              mode: string # Theme mode to activate <light|dark>
            ] {
              let target = sys host | get hostname
              let valid_modes = ["light" "dark"]

              if $mode not-in $valid_modes {
                error make $"Invalid mode: '($mode)'. Valid modes: ($valid_modes | str join ", ")"
              }

              if (get-active-theme $target) == $mode {
                if (input --default "yes" $"($mode) mode already active; proceed anyway? \(anything != 'yes' cancels\)") != "yes" {
                  print "Theme switch cancelled."
                  exit 0
                }
              }

              print $"Switching to the ($mode) theme."

              try {
                main deploy --specialisation $mode
              } catch {|e|
                error make $"Switching to the ($mode) theme failed: ($e)"
              }
            }
          '';
    };
}
