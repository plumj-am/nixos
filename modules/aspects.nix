{ inputs, ... }:
let
  commonModuleNames = [
    "disable-nix-documentation"
    "git"
    "env"
    "helix"
    "hjem"
    "jujutsu"
    "keys"
    "lf"
    "lib"
    "nix-index"
    "nix-settings"
    "openssh"
    "packages"
    "secret-manager"
    "shell"
    "shell-tools"
    "sudo"
    "ssh"
    "tailscale"
    "theme"
    "unfree"
    "users"
  ];

  getCommon = modules: map (name: modules.${name}) commonModuleNames;

  aspectsBaseLinux.imports =
    getCommon inputs.self.modules.nixos
    ++ (with inputs.self.modules.nixos; [
      disable-nano
      disks-extra-zram-swap
      dynamic-binaries
      locale
      netrc
      networking
      rebuild
      yubikey
    ]);

  aspectsBaseDarwin.imports =
    getCommon inputs.self.modules.darwin
    ++ (with inputs.self.modules.darwin; [
      fixes
      homebrew
    ]);
in
{
  flake.modules.nixos.aspectsBase = aspectsBaseLinux;
  flake.modules.darwin.aspectsBase = aspectsBaseDarwin;
}
