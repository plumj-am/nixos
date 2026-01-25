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

  flake.modules.nixos.nix-distributed-builder =
    { config, lib, ... }:
    let
      inherit (config.flake) keys;
      inherit (lib.lists) singleton;
    in
    {
      users.users.build = {
        description = "Build";
        isNormalUser = true;
        createHome = false;
        openssh.authorizedKeys.keys = keys.all;
        extraGroups = singleton "build";
      };

    };
}
