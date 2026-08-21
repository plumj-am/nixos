{ inputs, ... }:
let
  commonModuleNames = [
    "ai-options"
    "documentation"
    "git"
    "env"
    "helix"
    "hjem"
    "inputs-gcroot"
    "jujutsu"
    "keys"
    "lib"
    "nix"
    "openssh"
    "packages"
    "rebuild"
    "sops"
    "shell"
    "shell-tools"
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
        distributed-builds
        distributed-builder
        dynamic-binaries
        harmonia
        locale
        linux-kernel
        netrc
        networking
        nix-extra
        packages
        rebuild
        restic
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
        nix-extra
      ]);
  };
}
