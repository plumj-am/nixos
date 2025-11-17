{ lib, ... }: let
  inherit (lib) enabled;
in {
  home-manager.sharedModules = [{
    programs.nix-index = enabled {
      enableZshIntegration  = false;
      enableBashIntegration = false;
      enableFishIntegration = false;
    };
  }];
}
