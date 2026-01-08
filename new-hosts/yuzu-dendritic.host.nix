{ lib, inputs, ... }:
let
  inherit (lib) const;
  # Extend nixpkgs.lib with nix-darwin.lib, then our custom lib.
  lib' = inputs.os.lib.extend (const <| const <| inputs.os-darwin.lib);
  libCustom = lib'.extend <| import ../lib inputs;
in
{
  # Add yuzu-dendritic to the flake outputs
  config.flake.nixosConfigurations.yuzu-dendritic =
    libCustom.mkNixos "x86_64-linux" "yuzu-dendritic";
}
