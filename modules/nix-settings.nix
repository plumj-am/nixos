{
  config.flake.modules.nixos.nix-settings =
    {
      self,
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.attrsets)
        attrsToList
        filterAttrs
        removeAttrs
        mapAttrs
        mapAttrsToList
        ;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.trivial)
        const
        filter
        flip
        id
        ;
      inherit (lib.types) isType;
      inherit (lib.lists) optionals;

      registryMap = inputs |> filterAttrs (const <| isType "flake");
    in
    {
      nix.distributedBuilds = mkIf (config.networking.hostName != "yuzu") true; # No distributed builds for powerful desktop.
      nix.buildMachines = mkIf (config.networking.hostName != "yuzu") (
        self.nixosConfigurations
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
        )
      );

      nix.channel = {
        enable = false;
      };

      nix.gc = {
        automatic = true;
        options = "--delete-older-than 3d";
      }; # // optionalAttrs config.isLinux {  TODO: Add darwin config
      #   dates = "weekly";
      #   persistent = true;
      # };

      nix.nixPath =
        registryMap
        |> mapAttrsToList (name: value: "${name}=${value}")
        |> (if config.isDarwin then concatStringsSep ":" else id);

      nix.registry = registryMap // { default = inputs.os; } |> mapAttrs (_: flake: { inherit flake; });

      nix.settings =
        {
          extra-substituters = [
            "https://cache1.plumj.am?priority=10"
            "https://cache2.plumj.am?priority=10"
            "https://cache.garnix.io"
            "https://nix-community.cachix.org"
          ];

          extra-trusted-public-keys = [
            "cache1.plumj.am:rFlt5V4tYjsyo3QMRsaoO9VGYISJR+45tT35/6BpKsA="
            "cache2.plumj.am:IoMjbQ43lgHh8gMoEJj/VYK8c3Xbpc/TLRPKAaQSGas="
            "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];

          experimental-features = [
            "cgroups"
            "flakes"
            "nix-command"
            "pipe-operators"
          ];

          builders-use-substitutes = true;
          flake-registry = "";
          http-connections = 0;
          max-jobs = "auto";
          use-cgroups = true;
          show-trace = true;
          trusted-users = [
            "root"
            "@wheel"
            "build"
            "gitea-runner"
          ];
          warn-dirty = false;
        }
        |> flip removeAttrs (
          optionals config.isDarwin [
            "use-cgroups"
            "cgroups"
          ]
        );

      nix.extraOptions = mkIf config.isServer ''
        min-free = ${toString (2 * 1024 * 1024 * 1024)} # 2G
        max-free = ${toString (1 * 1024 * 1024 * 1024)} # 1G
      '';

      nix.optimise.automatic = true;
    };
}
