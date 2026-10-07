{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-links plugin: a plain click on a GitHub issue or pull-request link
      # opens a gh pane beside the clicked pane, not the web browser.
      packages.tern-links-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-links-plugin.toml" {
            schema = 1;
            id = "links";
            name = "tern-links";
            version = "0.1.0";
            description = "Open GitHub issue and pull-request links in a gh pane.";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-links-init.luau" # luau
              ''
                --!nonstrict
                local ISSUE = "https://github%.com/([^/]+)/([^/]+)/issues/(%d+)"
                local PULL = "https://github%.com/([^/]+)/([^/]+)/pull/(%d+)"

                local function command_of(link)
                  -- A held modifier keeps the click for the browser, so the user
                  -- has an escape hatch out of the gh pane.
                  if link.mods.cmd or link.mods.alt or link.mods.shift or link.mods.ctrl then
                    return nil
                  end

                  local owner, repo, number = string.match(link.url, ISSUE)
                  if owner ~= nil then
                    return "gh issue view " .. number .. " --repo " .. owner .. "/" .. repo .. " --comments"
                  end

                  owner, repo, number = string.match(link.url, PULL)
                  if owner ~= nil then
                    return "gh pr view " .. number .. " --repo " .. owner .. "/" .. repo
                  end

                  return nil
                end

                tern.route.link(function(link, cx)
                  local command = command_of(link)
                  if command == nil then
                    return nil
                  end

                  local origin = cx.session:focused()
                  if origin == nil then
                    return nil
                  end

                  -- A nil pane leaves the click to the built-in handling, so a
                  -- failed split does not swallow it.
                  local pane = cx.layout:split(origin, "right", { command = command })
                  if pane == nil then
                    cx:toast("error", "could not open gh pane")
                    return nil
                  end

                  return { handled = true }
                end)
              '';
        in
        pkgs.runCommand "tern-links-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
