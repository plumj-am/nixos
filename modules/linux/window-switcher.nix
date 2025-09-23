{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;

  window-switcher = pkgs.writeShellScriptBin "window-switcher" ''
    # Get all windows, format them nicely, let user select, then focus
    selected=$(${pkgs.hyprland}/bin/hyprctl clients -j | \
      ${pkgs.jq}/bin/jq -r '.[] | "\(.address) [\(.workspace.name)] \(.class) - \(.title)"' | \
      ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "Window: ")

    if [ -n "$selected" ]; then
      # Extract the address (first word) and focus the window
      address=$(echo "$selected" | awk '{print $1}')
      ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow address:$address
    fi
  '';
in mkIf config.isDesktop {
  environment.systemPackages = [
    window-switcher
  ];
}