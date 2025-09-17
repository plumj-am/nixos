{ lib, config, ... }: let
  inherit (lib) enabled mkIf;
in {
  environment.shellAliases.claude = "claude --continue";

  home-manager.sharedModules = [{
    programs.claude-code = mkIf config.isDesktop enabled;
  }];
}
