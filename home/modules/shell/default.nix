{ lib, ... }: {
  imports = lib.collectNix ./.
    |> lib.remove ./default.nix
    |> lib.remove ./aliases.nix;  # aliases.nix is data, not a module
}
