{
  home-manager.sharedModules = [{
    programs.ripgrep = {
      enable    = true;
      arguments = [ "--line-number" "--smart-case" ];
    };
  }];
}
