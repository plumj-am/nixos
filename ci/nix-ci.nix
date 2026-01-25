{ config, ... }:
let
  inherit (config.ciLib) commonPathsIgnore commonConcurrency stepsWithCheckout;

  commonArgs = ''--accept-flake-config --builders "" --no-link'';

  typeHelper =
    type: target:
    (
      if type == "build" then
        ".#${target}.config.system.build.toplevel"
      else
        ".#checks.x86_64-linux.${target}"
    );

  mkJob = type: name: target: runs-on: {
    inherit name runs-on;
    steps = stepsWithCheckout [
      {
        inherit name;
        run = "nix build ${typeHelper type target} ${commonArgs}";
      }
    ];
  };
in
{
  flake.actions-nix.workflows.".forgejo/workflows/nix-ci.yml" = {
    name = "Nix CI";
    on = {
      pull_request.paths-ignore = commonPathsIgnore [ ];
      push.paths-ignore = commonPathsIgnore [ ];
    };
    concurrency = commonConcurrency "nix-ci";
    jobs = {
      build-blackwell = mkJob "build" "Build: blackwell" "nixosConfigurations.blackwell" "blackwell";
      build-date = mkJob "build" "Build: date" "nixosConfigurations.date" "strong";
      build-kiwi = mkJob "build" "Build: kiwi" "nixosConfigurations.kiwi" "kiwi";
      # build-lime    = job "build" "Build: lime" "darwinConfigurations.lime" "strong";
      build-pear = mkJob "build" "Build: pear" "nixosConfigurations.pear" "strong";
      build-plum = mkJob "build" "Build: plum" "nixosConfigurations.plum" "plum";
      build-sloe = mkJob "build" "Build: sloe" "nixosConfigurations.sloe" "sloe";
      build-yuzu = mkJob "build" "Build: yuzu" "nixosConfigurations.yuzu" "strong";

      check-deadnix = mkJob "check" "Check: deadnix" "deadnix" "strong";
      check-statix = mkJob "check" "Check: statix" "statix" "strong";
      check-nix-paths = mkJob "check" "Check: legacy imports" "nix-path" "strong";
    };
  };
}
