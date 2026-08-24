{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.distributed-builds;
  flake.modules.nixos.distributed-builds =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) attrsToList;
      inherit (lib.lists) filter;
      inherit (lib.options) mkOption;
      inherit (lib.types) ints;
    in
    {
      options.systemInfo.distributedBuilder = {
        speedFactor = mkOption {
          type = ints.between 1 10;
          default = 1;
          description = "Relative speed factor for distributed builds";
        };
      };

      config = {
        nix.distributedBuilds = true;
        nix.buildMachines =
          inputs.self.nixosConfigurations
          |> attrsToList
          |> filter (
            { name }:
            name != config.networking.hostName
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
                "auto-allocate-uids"
                "benchmark"
                "big-parallel"
                "ca-derivations"
                "cgroups"
                "kvm"
                "nixos-test"
                "uid-range" # For nspawn vm tests.
              ];
              system = value.config.nixpkgs.hostPlatform.system;
            }
          );
      };
    };

  flake.modules.nixos.distributed-builder =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (config.flake) keys;
    in
    {
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
