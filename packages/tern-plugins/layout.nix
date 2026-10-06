{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      inherit (import ./_lib.nix) ideLayout;
    in
    {
      # tern loads a plugin from a directory holding plugin.toml plus the entry it
      # names, so both are written into one store path from strings, not loose files
      packages.tern-ide-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-ide-plugin.toml" {
            schema = 1;
            id = "ide";
            name = "tern-ide";
            version = "0.1.0";
            description = "IDE-like four-cell workspace layout with explicit split ratios.";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-ide-init.luau" # luau
              ''
                --!nonstrict
                ${ideLayout}

                tern.command({
                  id = "layout",
                  title = "IDE layout (four cells)",
                  icon = "layout",
                  group = "tern-ide",
                  run = function(cx)
                    local pane = ide_layout_pane(cx)
                    if pane == nil then
                      return
                    end
                    ide_layout_apply(cx, pane)
                  end,
                })

                -- tern silently drops a plugin bind whose chord the keymap preset already owns, so pick an unused one
                tern.bind("ctrl+alt+shift+f9", "plugin.ide.layout")
              '';
        in
        pkgs.runCommand "tern-ide-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
