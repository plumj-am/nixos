{ inputs, ... }:
let
  aspectsBaseLinux.imports = with inputs.self.modules.nixos; [
    disable-nano
    disable-nix-documentation
    disks-extra-zram-swap
    dynamic-binaries
    git
    env
    helix
    hjem
    jujutsu
    keys
    lf
    lib
    locale
    netrc
    networking
    nix-index
    nix-settings
    openssh
    packages
    rebuild
    secret-manager
    shell
    shell-tools
    sudo
    ssh
    systems
    tailscale
    theme
    unfree
    users
    virtualisation
    yubikey
  ];

  aspectsBaseDarwin.imports = with inputs.self.modules.darwin; [
    fixes
    disable-nix-documentation
    git
    env
    helix
    hjem
    jujutsu
    keys
    lf
    lib
    nix-index
    nix-settings
    openssh
    packages
    secret-manager
    shell
    shell-tools
    sudo
    ssh
    systems
    tailscale
    theme
    unfree
    users
  ];
in
{
  flake.modules.nixos.aspectsBase = aspectsBaseLinux;
  flake.modules.darwin.aspectsBase = aspectsBaseDarwin;
}
