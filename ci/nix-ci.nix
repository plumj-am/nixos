{ config, ... }:
let
  inherit (config.ciLib) commonPathsIgnore commonConcurrency stepsWithCheckout;

  # Helper for creating repetitive jobs.
  buildJob = name: target: runs-on: {
    inherit name runs-on;
    steps = stepsWithCheckout [
      {
        inherit name;
        run = # bash
          ''
            nix build .#${target}.config.system.build.toplevel --accept-flake-config --builders "" --no-link
          '';
      }
    ];
  };

  checkJob = name: target: {
    inherit name;
    runs-on = "plum";
    steps = stepsWithCheckout [
      {
        inherit name;
        run = # bash
          ''
            nix build .#checks.x86_64-linux.${target} --accept-flake-config --builders "" --no-link
          '';

      }
    ];
  };

in
{
  flake.actions-nix.workflows.".forgejo/workflows/nix-ci.yml" = {
    name = "Nix CI";
    on = {
      pull_request = {
        paths-ignore = commonPathsIgnore [ ];
      };
      push = {
        branches = [ "dendritic" ];
        paths-ignore = commonPathsIgnore [ ];
      };
      schedule = [
        # See `./update-flake-inputs.nix` for more details.
        { cron = "5 0 * * *"; } # Every day at 00:05. Keep ahead of `./update-flake-inputs.yml`.
      ];
    };
    concurrency = commonConcurrency "nix-ci";
    jobs = {
      build-date = buildJob "Build: date" "nixosConfigurations.date" "plum";
      build-kiwi = buildJob "Build: kiwi" "nixosConfigurations.kiwi" "kiwi";
      # build-lime = job "Build: lime" "darwinConfigurations.lime";
      build-pear = buildJob "Build: pear" "nixosConfigurations.pear" "plum";
      build-plum = buildJob "Build: plum" "nixosConfigurations.plum" "plum";
      build-yuzu = buildJob "Build: yuzu" "nixosConfigurations.yuzu" "plum";
      build-blackwell = buildJob "Build: blackwell" "nixosConfigurations.blackwell" "blackwell";

      check-deadnix = checkJob "Check: deadnix" "deadnix";
      check-statix = checkJob "Check: statix" "statix";
      check-nix-paths = checkJob "Check: legacy imports" "nix-path";

    };
  };
}
