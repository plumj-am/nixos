{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -w 0)" - | ${pkgs.swappy}/bin/swappy -f - -o - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
  '';

  screenshot-full = pkgs.writeShellScriptBin "screenshot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.swappy}/bin/swappy -f - -o - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
  '';

in mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.grim    # Screenshot utility.
    pkgs.slurp   # Screen area selection.
    pkgs.swappy  # Screenshot editor/annotator.
    screenshot
    screenshot-full
  ];
}
