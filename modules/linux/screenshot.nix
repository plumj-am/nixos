{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
  '';

  screenshot-clip = pkgs.writeShellScriptBin "screenshot-clip" ''
    if ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png; then
      ${pkgs.libnotify}/bin/notify-send "Screenshot" "Area screenshot copied to clipboard" --icon=image-x-generic
    else
      ${pkgs.libnotify}/bin/notify-send "Screenshot" "Failed to take screenshot" --icon=dialog-error --urgency=critical
    fi
  '';

  screenshot-full = pkgs.writeShellScriptBin "screenshot-full" ''
    if ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png; then
      ${pkgs.libnotify}/bin/notify-send "Screenshot" "Full screen screenshot copied to clipboard" --icon=image-x-generic
    else
      ${pkgs.libnotify}/bin/notify-send "Screenshot" "Failed to take screenshot" --icon=dialog-error --urgency=critical
    fi
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
