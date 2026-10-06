{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-tools plugin: open programs in a tab that closes when the
      # program exits, and return the focus where it came from.
      packages.tern-tools-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-tools-plugin.toml" {
            schema = 1;
            id = "tools";
            name = "tern-tools";
            version = "0.1.0";
            description = "Run programs in a tab that closes when the program exits.";
            icon = "terminal";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-tools-init.luau" # luau
              ''
                --!nonstrict
                -- Open PROGRAMS[PROGRAM] as a picture-in-picture overlay over the
                -- focused pane: the overlay goes away with its program, and the
                -- focus under it comes back.
                local PROGRAMS = {
                  jjui = { title = "jjui", command = "jjui" },
                  hunk = { title = "hunk", command = "hunk diff --watch" },
                }

                -- A floating pane is a picture-in-picture card; the float call takes
                -- no size, so the card is sized here. Tern sizes the pane's grid from
                -- the box, so the program gets the matching cells (95x47 for 760x798
                -- in a 950x998 window). Scoped to the focused card: a command
                -- floats then focuses, and a glance card or an unfocused float
                -- keeps Tern's own size. The percentages resolve against the
                -- window's stage, so the card centers in the window, not its owner.
                tern.css(
                  "overlay",
                  [[
                    .tn-pane.pip.on.pip-focus {
                      transform: none !important;
                      left: 10% !important;
                      top: 10% !important;
                      width: 80% !important;
                      height: 80% !important;
                    }
                  ]]
                )

                for name, program in pairs(PROGRAMS) do
                  tern.command({
                    id = name,
                    title = program.title,
                    icon = "terminal",
                    group = "tern-tools",
                    run = function(cx)
                      local origin = cx.session:focused()
                      if origin == nil then
                        cx:toast("error", "no focused pane to overlay " .. program.title)
                        return
                      end

                      -- A pane joins a tab through a split; the split stops showing
                      -- once the pane floats over the pane it came from.
                      local pane = cx.layout:split(origin, "right", { command = program.command }, { focus = false })
                      if pane == nil then
                        cx:toast("error", "could not open " .. program.title)
                        return
                      end

                      local floated, err = cx.layout:float(pane, origin)
                      if not floated then
                        cx.layout:close(pane)
                        cx:toast("error", "could not overlay " .. program.title, err)
                        return
                      end

                      -- A new overlay is a glance: focusing it expands it, so keys
                      -- reach the program, and closing it hands the focus back to
                      -- the pane it covers.
                      cx.layout:focus(pane)
                    end,
                  })
                end
              '';
        in
        pkgs.runCommand "tern-tools-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
