{
  home-manager.sharedModules = [{
    programs.zoxide = {
      enable = true;

      enableBashIntegration    = true;
      enableNushellIntegration = true;

      options = [ "--cmd cd" ];
    };
  }];
}
