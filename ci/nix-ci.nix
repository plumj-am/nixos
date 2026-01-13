{ config, ... }:
let
  inherit (config.ciLib) commonPathsIgnore commonConcurrency stepsWithCheckout;

  # Helper for creating repetitive jobs.
  job = name: target: runs-on: {
    inherit name;
    inherit runs-on;
    steps = stepsWithCheckout [
      {
        inherit name;
        run = # bash
          ''
            nix build ${target}.config.system.build.toplevel --accept-flake-config --builders "" --no-link
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
        branches = [ "**" ];
        paths-ignore = commonPathsIgnore [ ];
      };
      schedule = [
        # See `./update-flake-inputs.nix` for more details.
        { cron = "5 0 * * *"; } # Every day at 00:05. Keep ahead of `./update-flake-inputs.yml`.
      ];
    };
    concurrency = commonConcurrency "nix-ci";
    jobs = {
      build-date = job "Build: date" "nixosConfigurations.date" "plum";
      build-kiwi = job "Build: kiwi" "nixosConfigurations.kiwi" "kiwi";
      # build-lime = job "Build: lime" "darwinConfigurations.lime";
      build-pear = job "Build: pear" "nixosConfigurations.pear" "plum";
      build-plum = job "Build: plum" "nixosConfigurations.plum" "plum";
      build-yuzu = job "Build: yuzu" "nixosConfigurations.yuzu" "plum";
    };
  };
}
