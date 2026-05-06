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
          |> filter ({ name, value }: name != config.networking.hostName && value.config.systemSpecs.builder.enable)
          |> map (
            { name, value }:
            {
              hostName = name;
              maxJobs = value.config.systemSpecs.cores;
              protocol = "ssh-ng";
              sshUser = "build";
              sshKey = "/root/.ssh/id";
              speedFactor = value.config.systemSpecs.speedFactor;
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
      inherit (lib.lists) singleton;
      inherit (config.flake) keys;
    in
    {
      config = {
        systemSpecs.builder.enable = true;

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
