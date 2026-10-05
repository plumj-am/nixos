{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-tools plugin: open programs in a tab that closes when the
      # program exits.
      packages.tern-tools-plugin =
        let
          manifest = pkgs.writers.writeText "tern-tools-plugin.toml" ''
            schema = 1
            id = "tools"
            name = "tern-tools"
            version = "0.1.0"
            description = "Run programs in a tab that closes when the program exits."
            icon = "terminal"

            window = "init.luau"
          '';

          entry =
            pkgs.writers.writeText "tern-tools-init.luau" # luau
              ''
                --!nonstrict
                -- Open PROGRAMS[PROGRAM] in a tab, and close that tab when the program exits.
                local PROGRAMS = {
                  jjui = { title = "jjui", command = "jjui" },
                  hunk = { title = "hunk", command = "hunk diff --watch" },
                }

                -- Tabs this plugin opened, and the panes running a program in one.
                local tool_tabs = {}
                local program_panes = {}

                for name, program in pairs(PROGRAMS) do
                  tern.command({
                    id = name,
                    title = program.title,
                    icon = "terminal",
                    group = "tern-tools",
                    run = function(cx)
                      -- The program is the tab's pane program, so the pane ends
                      -- when the user quits the TUI.
                      local pane = cx.layout:new_tab({ command = program.command })
                      if pane == nil then
                        cx:toast("error", "could not open " .. program.title)
                        return
                      end

                      program_panes[pane] = true
                      local tab = cx.session:tab_of(pane)
                      if tab ~= nil then
                        tool_tabs[tab] = true
                      end
                    end,
                  })
                end

                -- The program, or the shell that reported it, ended: take the tab
                -- with it. A non-zero status is the program's exit; a zero status
                -- with no line is its shell finishing.
                tern.on("command_finished", function(ev, cx)
                  if not program_panes[ev.pane] then
                    return
                  end
                  program_panes[ev.pane] = nil

                  local tab = cx.session:tab_of(ev.pane)
                  if tab == nil or not tool_tabs[tab] then
                    return
                  end
                  tool_tabs[tab] = nil
                  cx.layout:close(ev.pane)
                end)

                -- Closed by hand, so nothing to remember any more.
                tern.on("pane_closed", function(ev, _cx)
                  program_panes[ev.pane] = nil
                end)
              '';
        in
        pkgs.runCommand "tern-tools-plugin" { } ''
          mkdir -p "$out"
          ln -s ${manifest} "$out/plugin.toml"
          ln -s ${entry} "$out/init.luau"
        '';
    };
}
