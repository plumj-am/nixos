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
                ${getExe pkgs.zoxide} init nushell --cmd=cd > $out
              ''
            }
          '';
      };
    };
}
