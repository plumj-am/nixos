{ inputs, ... }:
let
  commonModuleNames = [
    "ai-options"
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
    "tack"
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
        dynamic-binaries
        locale
        linux-kernel
        netrc
        networking
        nix-distributed-builds
        nix-distributed-builder
        rebuild
        system-info
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
