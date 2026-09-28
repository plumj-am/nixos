{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-direnv;
  flake.modules.common.nushell-direnv =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkBefore;
    in
    {
      programs.direnv = {
        enable = true;
        package = pkgs.direnv;
        silent = true;
        loadInNixShell = true;
        nix-direnv = {
          enable = true;
          package = pkgs.nix-direnv;
        };
      };

      hjemModule = {
        xdg.config.files."direnv/lib/nix-direnv.sh".source = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

        xdg.config.files."nushell/config.nu".text =
          mkBefore
            # nu
            ''
              $env.config.hooks.env_change.PWD = [
                {||
                  ${getExe pkgs.direnv} export json | from json | default {} | load-env
                }
              ]
            '';
      };
    };
}
