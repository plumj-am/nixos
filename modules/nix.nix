{ self, config, inputs, lib, pkgs, ... }: let
  inherit (lib) attrsToList concatStringsSep const disabled filter filterAttrs flip id isType mapAttrs mapAttrsToList merge mkAfter optionalAttrs optionals removeAttrs;

  registryMap = inputs
    |> filterAttrs (const <| isType "flake");
in {
  # will do later
  # nix.distributedBuilds = true;
  # nix.buildMachines = self.nixosConfigurations
  #   |> attrsToList
  #   |> filter ({ name, value }:
  #     name != (config.networking.hostName or config.networking.computerName or "") &&
  #     value.config.users.users ? build)
  #   |> map ({ name, value }: {
  #     hostName = name;
  #     maxJobs = 20;
  #     protocol = "ssh-ng";
  #     sshUser = "build";
  #     supportedFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test" ];
  #     system = value.config.nixpkgs.hostPlatform.system;
  #   });

  nix.channel = disabled;

  nix.gc = merge {
    automatic = true;
    options = "--delete-older-than 7d";
  } <| optionalAttrs (pkgs.stdenv.isLinux) {
    dates = "weekly";
    persistent = true;
  };

  nix.nixPath = registryMap
    |> mapAttrsToList (name: value: "${name}=${value}")
    |> (if pkgs.stdenv.isDarwin then concatStringsSep ":" else id);

  nix.registry = registryMap // { default = inputs.nixpkgs; }
    |> mapAttrs (_: flake: { inherit flake; });

  nix.settings = (import <| self + /flake.nix).nixConfig
    |> flip removeAttrs (optionals pkgs.stdenv.isDarwin [ "use-cgroups" "cgroups" ]);

  nix.optimise.automatic = true;
}
