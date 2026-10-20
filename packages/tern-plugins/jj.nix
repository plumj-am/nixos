{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      inherit (pkgs.lib) toJSON;

      inherit (import ./_channel.nix) channel;
      inherit (import ./_jj-host.nix) jjHost;
      inherit (import ./_jj-window.nix) jjWindow;
      inherit (import ./_lib.nix) ideLayout stepped;

      # Inlined into both halves. A hook's budget is too small for a file
      # read, so the settings are read as a table, not from a file. New
      # checkouts land in <workspace_root>/<repo>/<workspace-slug>
      settings = {
        workspace_root = "~/projects/tern-worktrees";
        create_bookmark = false;
        post_create = "try {direnv allow}";

        # A setting, not a post_create_action: a plugin cannot dispatch another plugin's action.
        ide_layout = true;

        status_remote = "origin";
      };

      settingsLuau = ''
        local SETTINGS = {
          workspace_root = ${toJSON settings.workspace_root},
          create_bookmark = ${if settings.create_bookmark then "true" else "false"},
          post_create = ${toJSON settings.post_create},
          ide_layout = ${if settings.ide_layout then "true" else "false"},
          status_remote = ${toJSON settings.status_remote},
        }
      '';

      # The tilde is expanded where the settings are used, because a
      # child process gets the tilde literally. The host half expands it
      # for the checkout path; the window half keeps the raw value.
      settingsWithExpansion = ''
        ${settingsLuau}

        -- Expanded here: a child process gets the tilde literally.
        local workspaceRoot = SETTINGS.workspace_root
        if string.sub(workspaceRoot, 1, 2) == "~/" then
          workspaceRoot = (tern.getenv("HOME") or "") .. string.sub(workspaceRoot, 2)
        end
        local createBookmark = SETTINGS.create_bookmark
        local postCreate = SETTINGS.post_create
        local ideLayoutEnabled = SETTINGS.ide_layout
        local statusRemote = SETTINGS.status_remote
      '';
    in
    {
      # tern-jj: Jujutsu workspace integration. create: fetch, workspace on @, tab.
      # open: list, focus or add tab. remove: snapshot, forget, delete checkout. status: bookmarks/change id, !, *N, +N/-N
      #
      # The plugin has two halves. The host half runs in the session
      # daemon, on its own worker thread, and owns the jj CLI, the status
      # refresh and the workspace work. The window half keeps the chrome,
      # the commands, the pickers and the tab work.
      #
      # The split is not a convenience: a window half hook has 4 ms for a
      # chrome formatter and 50 ms for everything else, and a call made
      # from inside another call keeps the outer call's deadline. The jj
      # CLI, the file reads and the daemon round trips all cost the
      # window's UI thread, so they run in the host half, where the
      # budget is 2 s and the thread is the host's own.
      packages.tern-jj-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-jj-plugin.toml" {
            schema = 1;
            id = "jj";
            name = "tern-jj";
            version = "0.1.0";
            description = "Create, open, remove and inspect Jujutsu workspaces from Tern.";
            icon = "branch";

            # No dialog block: the window half asks with cx:pick and
            # cx:prompt, which Tern draws over the focused pane.

            host = "host.luau";
            window = "init.luau";
          };

          host =
            pkgs.writers.writeText "tern-jj-host.luau" # luau
              (jjHost {
                settings = settingsWithExpansion;
                inherit channel;
              });

          window =
            pkgs.writers.writeText "tern-jj-window.luau" # luau
              (jjWindow {
                settings = settingsWithExpansion;
                inherit channel ideLayout stepped;
              });

          # The manifest's entry: the window half exceeds the load hook's
          # budget, so the entry compiles it on the first timer tick, where
          # the compile gets its own budget, and needs no settle.
          entry =
            pkgs.writers.writeText "tern-jj-entry.luau" # luau
              ''
                -- !nonstrict
                local started = false
                tern.timer(1, function()
                  if started then
                    return
                  end
                  started = true
                  local body = loadstring(tern.fs.read("window.luau"))
                  if type(body) ~= "function" then
                    tern.log.error("tern-jj: window.luau did not compile")
                    return
                  end
                  body()
                end)
              '';
        in
        pkgs.runCommand "tern-jj-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
          ln --symbolic ${window} "$out/window.luau"
          ln --symbolic ${host} "$out/host.luau"
        '';
    };
}
