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
              $env.config.hooks.env_change.PWD = (
                $env.config.hooks.env_change.PWD? | default [] | append [
                  {||
                    ${getExe pkgs.direnv} export json | from json | default {} | load-env
                  }
                  # For jj workspaces so git stuff still works.
                  {||
                    $env.GIT_DIR = match (${getExe pkgs.jujutsu} git root | complete) {
                      {exit_code: 0, stdout: $out} => { $out | str trim }
                      _ => { hide-env --ignore-errors GIT_DIR }
                    }
                  }
                ]
              )
            '';
      };
    };
}
