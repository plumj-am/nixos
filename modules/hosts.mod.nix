{ inputs, lib, ... }:
let
  inherit (builtins) readDir;
  inherit (lib)
    attrsToList
    const
    groupBy
    listToAttrs
    mapAttrs
    mapAttrs'
    nameValuePair
    removeSuffix
    ;

  # Extend nixpkgs.lib with nix-darwin.lib, then our custom lib.
  lib' = inputs.os.lib.extend (const <| const <| inputs.os-darwin.lib);
  libCustom = lib'.extend <| import ../lib inputs;

  rawHosts =
    readDir ../hosts
    |> mapAttrs' (
      name: _value: nameValuePair (removeSuffix ".nix" name) (import (../hosts + "/${name}") libCustom)
    );

  hostsByType =
    rawHosts
    |> attrsToList
    |> groupBy (
      { value, ... }:
      if value ? class && value.class == "nixos" then "nixosConfigurations" else "darwinConfigurations"
    )
    |> mapAttrs (
      const (hosts: hosts |> map ({ name, value }: nameValuePair name value.config) |> listToAttrs)
    );
in
{
  config.flake = lib.mkMerge [
    hostsByType
    {
      inherit inputs;
      lib = libCustom;

      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self;
        nixosConfigurations = hostsByType.nixosConfigurations;
      };
    }
  ];
}
