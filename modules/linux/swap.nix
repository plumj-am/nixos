{ lib, config, ... }: let
  inherit (lib) mkIf enabled;
in {
  zramSwap = mkIf config.isServer enabled;
}
