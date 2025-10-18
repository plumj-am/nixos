{ inputs, config, lib, pkgs, ... }: let
  inherit (lib) mkIf;
in {

  age.identityPaths = [
    (if config.isLinux then
      "${config.users.users.root.home}/.ssh/id"
    else
      "${config.users.users.${config.system.primaryUser}.home}/.ssh/id")
  ];

  environment.systemPackages = mkIf config.isDesktop [
    pkgs.agenix
    inputs.agenix-rekey.packages.${pkgs.system}.default
    pkgs.age-plugin-yubikey
  ];
}

