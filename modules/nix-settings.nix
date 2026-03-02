{ inputs, lib, ... }:
let
  inherit (lib.attrsets) filterAttrs mapAttrsToList;
  inherit (lib.trivial) const;
  inherit (lib.types) isType;
  inherit (lib.strings) concatStringsSep;
  inherit (lib) mkDefault;

  registryMap = inputs |> filterAttrs (const <| isType "flake");

  nixSettingsBase =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrs;
      inherit (lib.meta) getExe;

      dixHook =
        pkgs.writeShellScript "dix-hook" # sh
          ''
            exec >&2
            echo "For derivation $3:"
            ${getExe pkgs.dix} "$1" "$2"
          '';
    in
    {
      # nix.package = pkgs.nixVersions.latest; # Using determinate-nix which sets this.
      nix.channel = {
        enable = false;
      };

      nix.gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      };

      nix.registry = registryMap // { default = inputs.os; } |> mapAttrs (_: flake: { inherit flake; });

      nix.settings = {
        extra-substituters = [
          "https://cache.garnix.io"
          "https://nix-community.cachix.org"
        ];

        extra-trusted-public-keys = [
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
        cores = 0;
        use-cgroups = true;
        show-trace = true;
        trusted-users = [
          "root"
          "@wheel"
          "build"
          "gitea-runner"
        ];
        warn-dirty = false;
        use-xdg-base-directories = true;

        run-diff-hook = true;
        diff-hook = dixHook;
      };

      nix.optimise.automatic = true;
    };

  nixosNixPath = (registryMap |> mapAttrsToList (name: value: "${name}=${value}")) ++ [
    "nixpkgs=${inputs.os}"
  ];

  nixSettingsDesktopExtra = {
    nix.nixPath = nixosNixPath;

    nix.gc = {
      dates = "weekly";
      persistent = true;
    };

    nix.settings = {
      use-cgroups = true;
      experimental-features = [ "cgroups" ];
    };
  };

  nixSettingsServerExtra = {
    nix.nixPath = nixosNixPath;

    nix.gc = {
      options = mkDefault "--delete-older-than 1d";
      # Servers build and upload to S3 cache, so they can be more aggressive with GC.
      dates = "daily";
      persistent = true;
    };

    systemd.services.nix-daemon.serviceConfig = {
      MemoryAccounting = true;
      MemoryMax = "90%";
      OOMScoreAdjust = 500;
    };

    nix.extraOptions = ''
      min-free = 2G
    '';
  };

  nixSettingsDarwinExtra = {
    nix.nixPath =
      (registryMap |> mapAttrsToList (name: value: "${name}=${value}") |> concatStringsSep ":")
      ++ [ "nixpkgs=${inputs.os}" ];

  };
in
{
  flake.modules.nixos.nix-settings = nixSettingsBase;
  flake.modules.darwin.nix-settings = nixSettingsBase;

  flake.modules.nixos.nix-settings-extra-desktop = nixSettingsDesktopExtra;
  flake.modules.nixos.nix-settings-extra-server = nixSettingsServerExtra;
  flake.modules.darwin.nix-settings-extra-darwin = nixSettingsDarwinExtra;
}
