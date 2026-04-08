{
  flake.modules.common.lf =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule = {
        packages = singleton pkgs.lf;

        xdg.config.files."lf/lfrc".text = # rc
          ''
            cmd open-smart ''${{
                if [ -d "$f" ]; then
                    lf -remote "send $id cd '$f'"
                else
                    hx "$f"
                fi
            }}

            map <enter> open-smart
            map <escape> updir
          '';
      };
    };
}
