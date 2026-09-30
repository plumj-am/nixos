{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.distributed-builds;
  flake.modules.nixos.distributed-builds =
    {
      lib,
      config,
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
          self.nixosConfigurations
          |> attrsToList
          |> filter (
            # deadnix: skip
            { name, value }:
            name != config.networking.hostName && value.config.systemInfo.distributedBuilder.speedFactor != null
          )
          |> map (
            { name, value }:
            {
              hostName = name;
              maxJobs = value.config.systemInfo.threads;
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
    { lib, config, ... }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.lists) singleton;
      inherit (config.flake) entities;
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
          openssh.authorizedKeys.keys = mapAttrsToList (_: sshKey: sshKey) entities.sshKeys;
        };
      };
    };
}
