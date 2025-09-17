{ pkgs, lib, config, ... }:
{
  unfree.allowedNames = [ "claude-code" ];

  environment.shellAliases.claude = "claude --continue";

  environment.systemPackages = lib.optionals config.isDesktop [ pkgs.claude-code ];

  # There is a HM program from claude-code but unfree doesn't work the same
  # need to check it before I can enable it this way.
  # home-manager.sharedModules = [{
  #   programs.claude-code = mkIf config.isDesktop enabled;
  # }];
}
