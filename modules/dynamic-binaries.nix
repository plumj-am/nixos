{
  flake.modules.nixos.dynamic-binaries = {
    programs.nix-ld.enable = true;
  };
}
