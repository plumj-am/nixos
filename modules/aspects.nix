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
    "lib"
    "nix-index"
    "nix-settings"
    "openssh"
    "packages"
    "rebuild"
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
in
{
  flake.modules.nixos.aspectsBase = {
    imports =
      getCommon inputs.self.modules.nixos
      ++ (with inputs.self.modules.nixos; [
        disable-nano
        disks-extra-zram-swap
        dynamic-binaries
        locale
        linux-kernel
        netrc
        networking
        rebuild
        system-specs
        yubikey
      ]);
  };

  flake.modules.darwin.aspectsBase = {
    imports =
      getCommon inputs.self.modules.darwin
      ++ (with inputs.self.modules.darwin; [
        fixes
        homebrew
      ]);
  };
}
