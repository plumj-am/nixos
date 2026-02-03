{ inputs, ... }:
let
  commonModules.imports = with inputs.self.modules.nixos; [
    disable-nano
    disable-nix-documentation
    dynamic-binaries
    hjem
    keys
    lib
    locale
    netrc
    network
    nix-settings
    openssh
    packages
    rebuild
    secret-manager
    system
    tailscale
    theme
    unfree
    users
    virtualisation
    yubikey
  ];

  desktopModules.imports = with inputs.self.modules.nixos; [
    audio
    boot-systemd
    desktop-gui
    desktop-tools
    gammastep
    graphics
    hardware-desktop
    jujutsu-extra
    keyboard
    linux-kernel-zen
    mouse
    packages-extra-desktop
    power-menu
    process-management
    quickshell
    rust-desktop
    scratchpads
    sudo-desktop
    theme-extra-fonts
    theme-extra-scripts
    waybar
    window-manager
  ];

  serverModules.imports = with inputs.self.modules.nixos; [
    forgejo-action-runner
    linux-kernel
    nix-distributed-builds
    nix-distributed-builder
    prometheus-node-exporter
    sudo-server
  ];
in
{
  flake.modules.nixos.commonModules = commonModules;
  flake.modules.nixos.serverModules = serverModules;
  flake.modules.nixos.desktopModules = desktopModules;
}
