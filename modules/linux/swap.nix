{ lib, config, ... }: let
  inherit (lib) mkIf enabled;
in {
  zramSwap = mkIf config.isDesktopNotWsl enabled;
}
