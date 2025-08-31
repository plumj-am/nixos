{ lib, ... }: {
  imports = lib.collectNix ./. 
		|> lib.remove ./default.nix;
}
