{ pkgs, lib, config, ... }:
{
  unfree.allowedNames = [ "claude-code" "codex" ];

  environment.shellAliases = {
    claude = "claude --continue --fork-session";
    codex  = "codex resume --ask-for-approval untrusted";
  };

  environment.systemPackages = lib.optionals config.isDesktop [
    pkgs.claude-code
    pkgs.codex
  ];

  # There is a HM program from claude-code but unfree doesn't work the same
  # need to check it before I can enable it this way.
  # home-manager.sharedModules = [{
  #   programs.claude-code = mkIf config.isDesktop enabled;
  # }];
}
