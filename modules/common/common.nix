{ pkgs, ... }:
{
  environment.variables = {
    EDITOR   = "hx";
    SHELL    = "${pkgs.nushell}/bin/nu";
    BROWSER  = "wslview"; # use wslview for WSL
    TERMINAL = "zellij";
  };

  home-manager.sharedModules = [{
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];
  }];
}

