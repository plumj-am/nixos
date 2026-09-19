{ self, ... }:
let
  # uutils mv rejects a repeated --force, so a caller-supplied --force or -f
  # must be dropped before the wrapper adds its own:
  # <https://github.com/uutils/coreutils/issues/11321>.
  forcedMv =
    pkgs:
    pkgs.writers.writeNu "mv" # nu
      ''
        def main --wrapped [...args: string] {
          let arguments = (
            $args | reduce --fold {out: [], literal: false} {|arg, acc|
              if $acc.literal {
                {out: ($acc.out | append $arg), literal: true}
              } else if $arg == "--" {
                {out: ($acc.out | append $arg), literal: true}
              } else if $arg in ["-f" "--force"] {
                $acc
              } else if ($arg | str starts-with "--") {
                {out: ($acc.out | append $arg), literal: false}
              } else if ($arg | str starts-with "-") and ($arg | str contains "f") {
                let stripped = $arg | str replace --all "f" ""
                if $stripped == "-" { $acc } else {
                  {out: ($acc.out | append $stripped), literal: false}
                }
              } else {
                {out: ($acc.out | append $arg), literal: false}
              }
            }
            | get out
          )

          exec ${pkgs.uutils-coreutils-noprefix}/bin/mv --force ...$arguments
        }
      '';
in
{
  flake.modules.nixos.nuke = self.modules.nixos.nuke-coreutils;
  flake.modules.nixos.nuke-coreutils =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.filesystem) baseNameOf;
      inherit (lib.lists) head singleton;
      inherit (lib.strings) replicate stringLength;
      inherit (lib.trivial) flip;
    in
    {
      system.replaceDependencies.replacements =
        let
          candidates = [
            # Not ready for use yet: <https://github.com/uutils/acl>
            # {
            #   prev = pkgs.acl;
            #   final = pkgs.uutils-acl;
            #   finalName = "u-acl";
            # }
            {
              prev = pkgs.coreutils;
              final = pkgs.uutils-coreutils-noprefix;
              finalName = "u-coreutils";
            }
            {
              prev = pkgs.coreutils-full;
              final = pkgs.uutils-coreutils-noprefix;
              finalName = "u-coreutils";
            }
            {
              prev = pkgs.diffutils;
              final = pkgs.uutils-diffutils;
              finalName = "u-diffutils";
            }
            {
              prev = pkgs.findutils;
              final = pkgs.uutils-findutils;
              finalName = "u-findutils";
            }
            {
              prev = pkgs.gnused;
              final = pkgs.uutils-sed;
              finalName = "u-sed";
            }
            {
              prev = pkgs.gnutar;
              final = pkgs.uutils-tar;
              finalName = "u-tar";
            }
            {
              prev = pkgs.hostname;
              final = pkgs.uutils-hostname;
              finalName = "u-hostname";
            }
            {
              prev = pkgs.hostname-debian;
              final = pkgs.uutils-hostname;
              finalName = "u-hostname";
            }
            {
              prev = pkgs.procps;
              final = pkgs.uutils-procps;
              finalName = "u-procps";
            }
            # Waiting for nixpkgs uutils-shadow: <https://github.com/NixOS/nixpkgs/pull/546635>
            # {
            #   prev = pkgs.su;
            #   final = pkgs.uutils-shadow;
            #   finalName = "u-shadow";
            # }
            # {
            #   prev = pkgs.shadow;
            #   final = pkgs.uutils-shadow;
            #   finalName = "u-login";
            # }
            # Not ready for use yet: <https://github.com/uutils/util-linux>
            # {
            #   prev = pkgs.util-linux;
            #   final = pkgs.uutils-util-linux;
            #   finalName = "u-util-linux";
            # }
          ];
        in
        flip map candidates (
          {
            prev,
            final,
            finalName,
          }:
          let
            # Extract the actual store path name (without the hash) from a derivation
            oldStorePathName =
              let
                base = baseNameOf prev.outPath; # e.g. "hash-util-linux-2.42.2-bin"
                # Capture everything after the first dash
                match = lib.strings.match "^[^-]+-(.*)$" base;
              in
              assert match != null;
              head match;

            name =
              let
                padding = stringLength oldStorePathName - stringLength finalName;
              in
              assert padding >= 0;
              finalName + replicate padding "_";

            mvCompat = final == pkgs.uutils-coreutils-noprefix;
          in
          {
            oldDependency = prev;
            newDependency = pkgs.symlinkJoin {
              inherit name;
              paths = singleton final;

              # Until this is fixed: <https://github.com/uutils/coreutils/issues/11321>.
              # Without it, we get prompted for mv confirmation during activation.
              postBuild =
                if mvCompat then
                  # bash
                  ''
                    rm $out/bin/mv
                    cp ${forcedMv pkgs} $out/bin/mv
                  ''
                else
                  "";
            };
          }
        );

      nixpkgs.overlays = singleton (
        final: prev:
        let
          replaceCoreutils =
            program: rest:
            prev.${program}.override {
              coreutils = final.uutils-coreutils-noprefix;
            }
            // rest;
        in
        {
          alsa-ucm-conf = replaceCoreutils "alsa-ucm-conf" { };
          bash = replaceCoreutils "bash" { };
          mangohud = replaceCoreutils "mangohud" {
            # gnugrep = final.uutils-grep; # not in nixpkgs yet
            gnused = final.uutils-sed;
          };
          # networkmanager = replaceCoreutils "network-manager" {}; # Can't be done: leads to type mismatches.
          openresolv = replaceCoreutils "openresolv" { };
          systemd = replaceCoreutils "systemd" { }; # Uses coreutils for `${coreutils}/bin/false` lol...
          systemdMinimal = replaceCoreutils "systemdMinimal" { };
        }
      );
    };

  perSystem =
    { pkgs, ... }:
    {
      checks.mv-force-flag = pkgs.runCommand "mv-force-flag-check" { } ''
        set -euo pipefail

        mv=${forcedMv pkgs}

        mkdir work
        cd work
        printf 'new\n' > expected

        # A caller that passes -f, such as nix-direnv, must keep working.
        printf 'old\n' > target
        chmod 0444 target
        printf 'new\n' > source
        $mv -f source target
        cmp target expected

        printf 'old\n' > target
        chmod 0444 target
        printf 'new\n' > source
        $mv --force source target
        cmp target expected

        # Other short flags survive, including ones clustered with -f.
        printf 'old\n' > target
        printf 'new\n' > source
        $mv -nf source target
        printf 'old\n' | cmp - target

        # A file named like a flag stays reachable behind `--`.
        printf 'new\n' > ./-f
        $mv -- -f target
        cmp target expected

        touch $out
      '';
    };
}
