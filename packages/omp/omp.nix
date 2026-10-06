{ inputs, ... }:
{
  # `omp` with env vars.
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;

      omp = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp;
    in
    {
      packages.omp-wrapped =
        pkgs.writers.writeNuBin "omp" # nu
          ''
            def --wrapped main [...args: string] {
              let usable_cpus = ((sys cpu | length | default 2) // 4) | [$in 2] | math max | into string

              # `NIX_CONFIG` appends to `/etc/nix/nix.conf` instead of replacing it.
              # Last occurrence of an option wins. `--flags` always win over both.
              $env.NIX_CONFIG = $"($env.NIX_CONFIG? | default "")(char nl)max-jobs = ($usable_cpus)(char nl)cores = 1"

              # The environment form of `build.jobs`, with the rule
              # max 2 (threads / 5). `--jobs` still wins over this.
              $env.CARGO_BUILD_JOBS = $usable_cpus

              exec ${getExe omp} ...$args
            }
          '';
    };
}
