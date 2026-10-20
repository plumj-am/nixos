{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      inherit (import ./_lib.nix) ideLayout stepped;
    in
    {
      # plugin.toml and the entry it names are written into one store path
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
                ${stepped}

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

                    -- One step per pass. The layout splits twice, resizes
                    -- twice and opens an agent block, and every one of
                    -- those marshals IPC to the daemon. In one pass the
                    -- whole chain was billed to the command's 50 ms
                    -- budget: "command layout exceeded 50 ms".
                    local steps = ide_layout_steps(pane)
                    stepped(steps)
                  end,
                })

                -- tern drops a plugin bind whose chord the keymap preset owns
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
