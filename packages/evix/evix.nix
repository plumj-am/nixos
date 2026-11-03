{ inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      hasEvix = builtins.hasAttr system inputs.evix.packages;

      upstream = if hasEvix then inputs.evix.packages.${system}.evix else null;

      inherit (lib.meta) getExe;

      evixConstants = lib.constants.evix;
      remoteArgsList = lib.flatten (
        map (r: [
          "--remote"
          "${r.host}:${toString evixConstants.port}"
          pkgs.stdenv.hostPlatform.system
          (toString r.workers)
        ]) evixConstants.remotes
      );
      remoteArgsNu = "[ " + (lib.concatMapStringsSep " " (x: "\"${x}\"") remoteArgsList) + " ]";
      remoteHostsNu =
        "[ " + (lib.concatMapStringsSep " " (r: "\"${r.host}\"") evixConstants.remotes) + " ]";

      shim =
        if hasEvix then
          pkgs.writers.writeNuBin "evix" # nu
            ''
              # Nix's CLI promotes a plain path to `git+file` when it is a work
              # tree, while libnix parses the same string as `path:`. Both ends
              # of a remote evaluation must agree, or the archived source copy
              # is not the one the evaluator opens. Pin the flavour here and
              # pass the pinned ref to both `nix flake archive` and evix.
              def canonical-ref [ref: string] {
                let parts = ($ref | split row "#")
                let head = ($parts | first)
                let fragment = if (($parts | length) > 1) { "#" + ($parts | skip 1 | str join "#") } else { "" }
                let local = (
                  if ($head | str starts-with "/") {
                    $head
                  } else if ($head | str starts-with "path:") {
                    $head | str replace --regex "^path:" ""
                  } else if ($head == ".") or ($head | str starts-with "./") or ($head | str starts-with "../") {
                    $head | path expand
                  } else {
                    null
                  }
                )
                if $local == null {
                  return { ref: $ref, root: $head }
                }
                let root = if ($"($local)/.git" | path exists) {
                  $"git+file://($local)"
                } else {
                  $"path:($local)"
                }
                { ref: $"($root)($fragment)", root: $root }
              }

              def --wrapped main [...args] {
                # evix re-execs its own binary to become a worker subprocess.
                # If the shim is the entry point, that child must be upstream's
                # binary or the worker protocol never starts.
                if ("EVIX_WORKER" in $env) {
                  exec ${getExe upstream} ...$args
                }

                let subcommand = ($args | first | default "")
                # `daemon` and `worker` take none of the evaluation flags.
                if $subcommand == "daemon" or $subcommand == "worker" {
                  exec ${getExe upstream} ...$args
                }

                mut rebuilt = []
                mut roots = []
                mut overrides = []
                mut has_remote = false
                mut has_token = false
                mut i = 0
                let n = ($args | length)

                while ($i < $n) {
                  let a = ($args | get $i)
                  if ($a == "--remote") or ($a | str starts-with "--remote=") {
                    $has_remote = true
                  }
                  if ($a == "--remote-token") or ($a | str starts-with "--remote-token=") {
                    $has_token = true
                  }
                  if ($a == "--flake") and ($i + 1 < $n) {
                    let canon = (canonical-ref ($args | get ($i + 1)))
                    $rebuilt = ($rebuilt ++ ["--flake" $canon.ref])
                    $roots = ($roots | append $canon.root)
                    $i = $i + 2
                    continue
                  }
                  if ($a | str starts-with "--flake=") {
                    let canon = (canonical-ref ($a | str replace "--flake=" ""))
                    $rebuilt = ($rebuilt | append $"--flake=($canon.ref)")
                    $roots = ($roots | append $canon.root)
                    $i = $i + 1
                    continue
                  }
                  if ($a == "--override-input") and ($i + 2 < $n) {
                    # The archive pass locks inputs itself, so it needs the same
                    # overrides or their paths stay virtual.
                    let ov = ["--override-input" ($args | get ($i + 1)) ($args | get ($i + 2))]
                    $overrides = ($overrides ++ $ov)
                    $rebuilt = ($rebuilt ++ $ov)
                    $i = $i + 3
                    continue
                  }
                  $rebuilt = ($rebuilt | append $a)
                  $i = $i + 1
                }

                let local_only = ($env.EVIX_LOCAL_ONLY? | default "")
                # `watch` stays local: sources are shipped once per invocation,
                # and each edit produces a new source path the remotes do not
                # have, so remote workers would fail on the first change.
                let inject_remotes = (not $has_remote) and ($local_only == "") and ($subcommand != "watch")
                let token = if $inject_remotes {
                  if ($env.EVIX_REMOTE_TOKEN? | default "") != "" {
                    $env.EVIX_REMOTE_TOKEN
                  } else if ("/run/secrets/evix-remote-token" | path exists) {
                    open "/run/secrets/evix-remote-token" | str trim
                  } else {
                    ""
                  }
                } else {
                  ""
                }

                # `lockFlake` resolves the graph but does not copy the flake's
                # source tree into the store; the evaluator then reads that
                # `-source` path as a file and fails. `nix flake archive`
                # performs the copy without evaluating. With remotes, `--to`
                # both copies locally and ships the path plus its inputs, so
                # one call per host replaces the separate local archive.
                # `query` only reads a warm session and skips all of this; it
                # still carries the remote flags because the daemon keys
                # sessions on the whole evaluation config.
                if $subcommand != "query" {
                  for root in $roots {
                    if $inject_remotes {
                      let ov = $overrides
                      ${remoteHostsNu} | par-each {|host| ^nix flake archive --to $"ssh://($host)" $root ...$ov | ignore } | ignore
                    } else {
                      ^nix flake archive $root ...$overrides | ignore
                    }
                  }
                }

                # Environment, not argv: the token must not be world-readable
                # through `ps` on a shared host. evix reads the same variable.
                if $token != "" and not $has_token {
                  $env.EVIX_REMOTE_TOKEN = $token
                }

                mut extra = []
                if $inject_remotes {
                  $extra = ${remoteArgsNu}
                }

                exec ${getExe upstream} ...$rebuilt ...$extra
              }
            ''
        else
          null;
    in
    {
      packages = lib.optionalAttrs hasEvix {
        evix = pkgs.symlinkJoin {
          name = "evix";
          paths = [ upstream ];
          postBuild = ''
            rm $out/bin/evix
            ln -s ${shim}/bin/evix $out/bin/evix
          '';
        };
      };
    };
}
