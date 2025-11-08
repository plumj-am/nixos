{ self, config, inputs, lib, ... }: let
  inherit (lib) attrsToList concatStringsSep const disabled filter filterAttrs flip id isType mapAttrs mapAttrsToList merge optionalAttrs optionals removeAttrs mkIf;
  inherit (config.networking) hostName;

  registryMap = inputs
    |> filterAttrs (const <| isType "flake");
in {
  nix.distributedBuilds = mkIf (hostName != "yuzu") true; # No distributed builds for powerful desktop.
  nix.buildMachines     = mkIf (hostName != "yuzu") (
    self.nixosConfigurations
    |> attrsToList
    |> filter ({ name, value }:
      name != config.networking.hostName &&
      value.config.users.users ? build)
    |> map ({ name, value }: {
      hostName          = name;
      maxJobs           = 25; # This is handled by remote anyway so not sure what difference it makes..
      protocol          = "ssh-ng";
      sshUser           = "build";
      sshKey            = "/root/.ssh/id";
      supportedFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test" ];
      system            = value.config.nixpkgs.hostPlatform.system;
    })
  );

  nix.channel = disabled;

  nix.gc = merge {
    automatic  = true;
    options    = "--delete-older-than 7d";
  } <| optionalAttrs (config.isLinux) {
    dates      = "weekly";
    persistent = true;
  };

  nix.nixPath = registryMap
    |> mapAttrsToList (name: value: "${name}=${value}")
    |> (if config.isDarwin then concatStringsSep ":" else id);

  nix.registry = registryMap // { default = inputs.nixpkgs; }
    |> mapAttrs (_: flake: { inherit flake; });

  nix.settings = (import <| self + /flake.nix).nixConfig
    |> flip removeAttrs (optionals config.isDarwin [ "use-cgroups" "cgroups" ]);

  nix.optimise.automatic = true;

}
