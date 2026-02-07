{ inputs, ... }:
let
  modulesBaseLinux.imports = with inputs.self.modules.nixos; [
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
    lib
    locale
    netrc
    network
    nix-settings
    openssh
    packages
    rebuild
    secret-manager
    shell
    shell-tools
    sudo
    ssh
    system
    tailscale
    theme
    unfree
    users
    virtualisation
    yubikey
  ];

  modulesBaseDarwin.imports = with inputs.self.modules.darwin; [
    disable-nix-documentation
    git
    env
    helix
    hjem
    jujutsu
    keys
    lib
    network
    nix-settings
    openssh
    packages
    secret-manager
    shell
    shell-tools
    sudo
    ssh
    system
    tailscale
    theme
    unfree
    users
  ];
in
{
  flake.modules.nixos.modulesBase = modulesBaseLinux;
  flake.modules.darwin.modulesBase = modulesBaseDarwin;
}
