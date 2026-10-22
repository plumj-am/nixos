{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-tools: a program runs in a tab that closes with it, and the focus
      # comes back
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
                -- Open a program as a picture-in-picture overlay over the focused
                -- pane: it goes away with its program, and the focus comes back
                local PROGRAMS = {
                  jjui = { title = "jjui", command = "jjui" },
                  hunk = { title = "hunk", command = "hunk diff --watch" },
                }

                -- A float takes no size, so the card is sized here (95x47 cells for
                -- 760x798 in a 950x998 window). Scoped to the focused card, because a
                -- command floats then focuses while a glance card keeps Tern's own
                -- size. The percentages resolve against the window's stage, not the
                -- owner, so the card centres in the window.
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
                      -- once the pane floats
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
                      -- reach the program
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
