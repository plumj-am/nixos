{ self, ... }:
{
  flake.modules.common.nushell = self.modules.common.nushell-zoxide;
  flake.modules.common.nushell-zoxide =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter;
    in
    {
      environment.systemPackages = singleton pkgs.zoxide;

      hjemModule = {
        xdg.config.files."nushell/config.nu".text =
          # nu
          mkAfter ''
            source ${
              pkgs.runCommand "zoxide-init.nu" { } ''
                ${getExe pkgs.zoxide} init nushell --cmd=cd > raw.nu

                # zoxide's generated hook calls bare `zoxide`, which nushell
                # resolves through $env.PATH when the hook fires. PATH is not
                # ready yet: sessionVariables (load-env) are applied after
                # config.nu is sourced, so /run/current-system/sw/bin is still
                # missing and the hook fails with "zoxide not found". Call the
                # store path directly instead.
                sed -i 's|\^zoxide |\^${getExe pkgs.zoxide} |g' raw.nu

                cat raw.nu > $out
              ''
            }
          '';
      };
    };
}
