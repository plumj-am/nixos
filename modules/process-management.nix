{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.process-management;
  flake.modules.nixos.process-management =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
    in
    {
      environment.systemPackages =
        singleton
        <|
          pkgs.writers.writeNuBin "process-monitor" # nu
            ''
              const CLASS_NAME = "btm-popup"

              let existing = try {
                niri msg --json windows
                | from json
                | where app_id? == $CLASS_NAME
              } catch { return }


              if ($existing | is-not-empty) {
                niri msg action close-window --id $existing
              } else {
                (${getExe self.packages.${pkgs.stdenv.hostPlatform.system}.tern}
                  --app-id $CLASS_NAME
                  --title-placeholder "Process Monitor"
                  --command ${getExe pkgs.bottom} --basic)
              }
            '';
    };
}
