{ inputs, lib, ... }:
let
  inherit (builtins) pathExists readDir;
  inherit (lib)
    filterAttrs
    hasSuffix
    mapAttrs'
    nameValuePair
    removeSuffix
    ;

  newHostsDir = ../new-hosts;
  hasNewHosts = pathExists newHostsDir;

  # Read all .host.nix files from new-hosts directory
  newHostsFiles =
    if hasNewHosts
    then
      readDir newHostsDir
      |> filterAttrs (name: type: type == "regular" && hasSuffix ".host.nix" name)
      |> mapAttrs' (
        name: _value:
          nameValuePair (removeSuffix ".host.nix" name) (import (newHostsDir + "/${name}") { inherit lib inputs; })
      )
    else { };
in
{
  # Each .host.nix file should return a flake-parts module that sets config.flake.*
  imports = builtins.attrValues newHostsFiles;
}
