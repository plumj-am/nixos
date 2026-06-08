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
      inherit (lib.lists) filter;
    in
    {
      config = {
        nix.distributedBuilds = true;
        nix.buildMachines =
          inputs.self.nixosConfigurations
          |> attrsToList
          |> filter (
            { name, value }:
            name != config.networking.hostName && value.config.systemInfo.distributedBuilder.enable
          )
          |> map (
            { name, value }:
            {
              hostName = name;
              maxJobs = value.config.systemInfo.cores;
              protocol = "ssh-ng";
              sshUser = "build";
              sshKey = "/root/.ssh/id";
              speedFactor = value.config.systemInfo.distributedBuilder.speedFactor;
              supportedFeatures = [
                "benchmark"
                "big-parallel"
                "kvm"
                "nixos-test"
                "uid-range" # For nspawn vm tests.
              ];
              system = value.config.nixpkgs.hostPlatform.system;
            }
          );
      };
    };

  flake.modules.nixos.nix-distributed-builder =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.options) mkOption;
      inherit (lib.types) bool ints;
      inherit (config.flake) keys;
    in
    {
      options.systemInfo.distributedBuilder = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Whether this host participates as a distributed Nix builder";
        };
        speedFactor = mkOption {
          type = ints.between 1 10;
          default = 1;
          description = "Relative speed factor for distributed builds";
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
