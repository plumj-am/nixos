{
  flake.modules.nixos.process-management =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      processMonitor =
        pkgs.writeScriptBin "process-monitor" # nu
          ''
            #!${pkgs.nushell}/bin/nu
            const CLASS_NAME = "btm-popup"

            let existing = try {
              niri msg --json windows
              | from json
              | where app_id? == $CLASS_NAME
            } catch { return }


            if ($existing | is-not-empty) {
              niri msg action close-window --id $existing
            } else {
              (rio
                --detach
                --app-id $CLASS_NAME
                --title-placeholder "Process Monitor"
                btm --basic)
            }
          '';

    in
    {
      hjem.extraModule = {
        packages = singleton processMonitor;
      };
    };
}
