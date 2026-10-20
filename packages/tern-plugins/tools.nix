{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      inherit (import ./_lib.nix) stepped;
    in
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
                ${stepped}

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

                      -- One step per pass. The split waits for the
                      -- program to start, and the daemon holds that wait
                      -- for 50 ms; the same 50 ms is the command's own
                      -- budget, so a split with a command in it ended as
                      -- "command jjui exceeded 50 ms". Each step gets
                      -- its own budget instead.
                      local state = { origin = origin, pane = nil }

                      stepped({
                        -- A pane joins a tab through a split; the split stops showing
                        -- once the pane floats
                        function(step_cx)
                          local pane = step_cx.layout:split(state.origin, "right", { command = program.command }, { focus = false })
                          if pane == nil then
                            step_cx:toast("error", "could not open " .. program.title)
                            return false
                          end
                          state.pane = pane
                          return true
                        end,
                        function(step_cx)
                          local floated, err = step_cx.layout:float(state.pane, state.origin)
                          if not floated then
                            step_cx.layout:close(state.pane)
                            step_cx:toast("error", "could not overlay " .. program.title, err)
                            return false
                          end
                          return true
                        end,
                        function(step_cx)
                          -- A new overlay is a glance: focusing it expands it, so keys
                          -- reach the program
                          step_cx.layout:focus(state.pane)
                          return true
                        end,
                      })
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
