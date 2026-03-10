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
      inherit (lib) filter;
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
              maxJobs = value.config.nix-builder.cores;
              protocol = "ssh-ng";
              sshUser = "build";
              sshKey = "/root/.ssh/id";
              speedFactor = value.config.nix-builder.speedFactor;
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
      inherit (lib.options) mkOption;
      inherit (lib.lists) singleton;
      inherit (lib.types) ints;
      inherit (config.flake) keys;
    in
    {
      options.nix-builder = {
        speedFactor = mkOption {
          type = ints.between 1 5;
          default = null;
          description = "Speed factor for this machine when used as a distributed build machine";
        };

        cores = mkOption {
          type = ints.between 1 25;
          default = 25;
          description = "Number of cores for the distributed build machine";
        };
      };

      config = {
        services.openssh.settings = {
          AllowUsers = singleton "build";
          AllowGroups = singleton "build";
        };

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
