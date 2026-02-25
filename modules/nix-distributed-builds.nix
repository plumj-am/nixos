{
  flake.modules.nixos.nix-distributed-builds =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) attrsToList;
      inherit (builtins) filter;
    in
    {
      config = {
        nix.distributedBuilds = true;
        nix.buildMachines =
          inputs.self.nixosConfigurations
          |> attrsToList
          |> filter ({ name, value }: name != config.networking.hostName && value.config.users.users ? build)
          |> map (
            { name, value }:
            {
              hostName = name;
              maxJobs = 25; # This is handled by remote anyway so not sure what difference it makes..
              protocol = "ssh-ng";
              sshUser = "build";
              sshKey = "/root/.ssh/id";
              speedFactor = value.config.nixBuildMachineSpeedFactor;
              supportedFeatures = [
                "benchmark"
                "big-parallel"
                "kvm"
                "nixos-test"
              ];
              system = value.config.nixpkgs.hostPlatform.system;
            }
          );
      };
    };

  flake.modules.nixos.nix-distributed-builder =
    { config, lib, ... }:
    let
      inherit (config.flake) keys;
      inherit (lib.options) mkOption;
      inherit (lib.types) ints;
    in
    {
      options.nixBuildMachineSpeedFactor = mkOption {
        type = ints.between 1 5;
        default = null;
        description = "Speed factor for this machine when used as a distributed build machine";
      };

      config = {
        users.groups.build = { };

        users.users.build = {
          description = "Build";
          group = "build";
          isSystemUser = true;
          useDefaultShell = true;
          openssh.authorizedKeys.keys = keys.all;
        };
      };
    };
}
