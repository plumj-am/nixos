{ config, lib, pkgs, ... }:
{
  environment.variables = {
    EDITOR   = "hx";
    SHELL    = "${pkgs.nushell}/bin/nu";
    TERMINAL = "zellij";
  } // lib.optionalAttrs config.isWsl {
    BROWSER = "wslview"; # use wslview for WSL
  };

  home-manager.sharedModules = [{
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];
  }];
}

