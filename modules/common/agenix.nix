{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;
in {

  age.identityPaths = [
    (if config.isLinux then
      "/root/.ssh/id"
    else
      "/Users/${config.system.primaryUser}/.ssh/id")
  ];

  environment = mkIf config.isDesktop {
    shellAliases.agenix = "agenix --identity ~/.ssh/id";

    systemPackages = [ pkgs.agenix ];
  };
}

