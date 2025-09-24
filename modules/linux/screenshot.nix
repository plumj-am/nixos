{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
  '';

  screenshot-clip = pkgs.writeShellScriptBin "screenshot-clip" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
  '';

  screenshot-full = pkgs.writeShellScriptBin "screenshot-full" ''
    ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
  '';

in mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.grim    # Screenshot utility.
    pkgs.slurp   # Screen area selection.
    pkgs.swappy  # Screenshot editor/annotator.
    screenshot
    screenshot-clip
    screenshot-full
  ];

  home-manager.sharedModules = [{
    # Desktop entries allow them to appear in Fuzzel.
    xdg.desktopEntries.screenshot = {
      name     = "Screenshot";
      exec     = "screenshot";
      terminal = false;
    };

    xdg.desktopEntries.screenshot-clip = {
      name     = "Screenshot Clipboard";
      exec     = "screenshot-clip";
      terminal = false;
    };

    xdg.desktopEntries.screenshot-full = {
      name     = "Screenshot Full";
      exec     = "screenshot-full";
      terminal = false;
    };
  }];
}
