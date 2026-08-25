{ self, ... }:
{
  flake.modules.darwin.desktop.imports = with self.modules.darwin; [
    editor-extra
    peripherals
    radicle
    rio
    rust-desktop
    sudo-desktop
    theme-extra-fonts
  ];

  flake.modules.nixos.desktop.imports = with self.modules.nixos; [
    audio
    boot-optimise
    boot-systemd
    colour-picker
    desktop-gui
    discord
    disks-normal
    docker-rootless
    editor-extra
    emacs
    file-manager
    forgejo-cli
    gammastep
    graphics
    hardware-desktop
    haskell
    helium
    keepassxc
    nextcloud-client
    packages-gui
    packages-cli
    peripherals
    pijul
    process-management
    quickshell
    rio
    rust-desktop
    radicle
    scratchpads
    sudo-desktop
    swap-partition
    theme-extra-fonts
    theme-extra-scripts
    video-player
    window-manager
    zyouz
  ];

  flake.modules.nixos.server.imports = with self.modules.nixos; [
    boot-grub
    disks-server
    forgejo-runner
    swapfile
    sudo-server
  ];

  flake.modules.nixos.ai-agents.imports = with self.modules.nixos; [
    commandcode
    omp
    opencode
  ];

  flake.modules.nixos.web-server.imports = with self.modules.nixos; [
    acme
    nginx
  ];
}
