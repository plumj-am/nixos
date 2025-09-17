{ lib, ... }: let
  inherit (lib) enabled;
in {
  environment.shellAliases = {
      ls  = "eza";
      sl  = "eza";
      ll  = "eza -la";
      la  = "eza -a";
      lsa = "eza -a";
      lsl = "eza -l -a";
  };
  home-manager.sharedModules = [{
    programs.eza = enabled;
  }];
}
