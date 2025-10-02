{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;
in {

  age.identityPaths = [
    (if config.isLinux then
      "${config.users.users.root.home}/.ssh/id"
    else
      "${config.users.users.${config.system.primaryUser}.home}/.ssh/id")
  ];

  environment = mkIf config.isDesktop {
    shellAliases.agenix = if config.isLinux then
      "agenix --identity ${config.users.users.root.home}/.ssh/id"
    else
      "agenix --identity ${config.users.users.${config.system.primaryUser}.home}/.ssh/id";

    systemPackages = [ pkgs.agenix ];
  };
}

