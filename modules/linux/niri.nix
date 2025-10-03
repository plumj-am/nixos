{ lib, config, ... }: let
  inherit (lib) mkIf;
in mkIf config.isDesktopNotWsl {
  programs.niri.enable = true;
}
