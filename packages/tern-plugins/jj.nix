{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      inherit (pkgs.lib) toJSON;

      inherit (import ./_lib.nix) ideLayout;

      # Inlined into the window half: a hook's budget is too small for a file read. New checkouts land in <workspace_root>/<repo>/<workspace-slug>
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
    in
    {
      # tern-jj: Jujutsu workspace integration. create: fetch, workspace on @, tab.
      # open: list, focus or add tab. remove: snapshot, forget, delete checkout. status: bookmarks/change id, !, *N, +N/-N
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

            window = "init.luau";
          };
          window =
            pkgs.writers.writeText "tern-jj-window.luau" # luau
              ''
                  -- !nonstrict
                  ${settingsLuau}

                  ${ideLayout}

                  local STATUS_TEMPLATE = table.concat({
                    'if(conflict, "1", "") ++ "\\x1f" ++ ',
                    'if(empty, "1", "") ++ "\\x1f" ++ ',
                    'change_id.shortest(12) ++ "\\x1f" ++ ',
                    'self.diff().files().len() ++ "\\x1f" ++ ',
                    'local_bookmarks.map(|b| b.name()).join(" ") ++ "\\n"',
                  })

                  -- Expanded here: a child process gets the tilde literally
                  local workspaceRoot = SETTINGS.workspace_root
                  if string.sub(workspaceRoot, 1, 2) == "~/" then
                    workspaceRoot = (tern.getenv("HOME") or "") .. string.sub(workspaceRoot, 2)
                  end
                  local createBookmark = SETTINGS.create_bookmark
                  local postCreate = SETTINGS.post_create
                  local ideLayoutEnabled = SETTINGS.ide_layout
                  local statusRemote = SETTINGS.status_remote

                  local function trim(text)
                    return (string.gsub(text or "", "%s+$", ""))
                  end

                  local function lines(text)
                    local out = {}
                    for line in string.gmatch(text or "", "([^\n]*)\n?") do
                      if line ~= "" then
                        table.insert(out, line)
                      end
                    end
                    return out
                  end

                  -- Reports are queued: raised in a jj callback, the cx is already dead
                  local reports = {}

                  local function show(cx, level, text, sub)
                    cx:toast(level, text, sub)
                  end

                  local function warn(cx, level, text, sub)
                    tern.log.warn(text, sub)
                    table.insert(reports, { level = level, text = text, sub = sub })
                  end

                  local function failed(cx, action, result)
                    local detail = trim(result.stderr)
                    if detail == "" then
                      detail = trim(result.stdout)
                    end
                    warn(cx, "error", action .. " failed", detail ~= "" and detail or nil)
                  end

                  local inflight = 0

                  local function jj(args, opts, on_done)
                    if type(opts) == "function" then
                      on_done, opts = opts, nil
                    end
                    if on_done ~= nil then
                      inflight = inflight + 1
                    end
                    tern.process.run(args, opts or {}, function(result)
                      if on_done ~= nil then
                        table.insert(reports, { jj_next = on_done, result = result })
                      end
                    end)
                  end

                  local function root_of(cwd, cb)
                    jj({ "jj", "--no-pager", "--ignore-working-copy", "-R", cwd, "workspace", "root" }, function(result)
                      local root = trim(result.stdout)
                      if result.status ~= 0 or root == "" then
                        return nil, cwd
                      end
                      return nil, root
                    end)
                  end

                local function main_root_of(root)
                  local pointer = root .. "/.jj/repo"
                  if not tern.fs.exists(pointer) then
                    return nil
                  end

                  local ok, text = pcall(tern.fs.read, pointer)
                  if ok and text ~= nil then
                    -- Relative to `<root>/.jj`, not `<root>`
                    local store = trim(text)
                    local joined = string.sub(store, 1, 1) == "/" and store or (root .. "/.jj/" .. store)

                    -- Normalised here; tern.fs has no path resolution
                    local segments = {}
                    for part in string.gmatch(joined, "[^/]+") do
                      if part == ".." then
                        table.remove(segments)
                      elseif part ~= "." then
                        table.insert(segments, part)
                      end
                    end

                    local resolved = "/" .. table.concat(segments, "/")

                    local main = string.match(resolved, "^(.*)/%.jj/repo$")
                    if main == nil or main == "" then
                      return nil
                    end
                    return main
                  end

                  return root
                end

                  local function repo_name(main_root)
                    local name = string.match(main_root, "([^/]+)$")
                    if name == nil or name == "" then
                      return "repository"
                    end
                    return name
                  end

                  -- A workspace name is jj's: [A-Za-z0-9._/-]
                  local function valid_name(name)
                    if type(name) ~= "string" or name == "" then
                      return false
                    end
                    return string.match(name, "^[%w._/%-]+$") ~= nil
                  end

                  local function slug(name)
                    local out = string.gsub(string.lower(name), "[^%w]+", "-")
                    out = string.gsub(out, "^%-+", "")
                    out = string.gsub(out, "%-+$", "")
                    if out == "" then
                      return "workspace"
                    end
                    return out
                  end

                  local tabs = {}

                  local function focus_tab(cx, tab)
                    for _, info in ipairs(cx.session:tabs()) do
                      if info.id == tab then
                        cx.layout:focus(info.pane)
                        return true
                      end
                    end
                    return false
                  end

                  -- A workspace owns its tab, so every pane of that tab goes.
                  local function close_tab(cx, tab)
                    local leaves = {}
                    for _, info in ipairs(cx.session:panes()) do
                      if info.tab == tab then
                        table.insert(leaves, info.pane)
                      end
                    end
                    if #leaves == 0 then
                      return false
                    end
                    for _, pane in ipairs(leaves) do
                      local ok, err = pcall(cx.layout.close, cx.layout, pane)
                      if not ok then
                        tern.log.info("tern-jj: pane already closed", pane, err)
                      end
                    end
                    return true
                  end

                  -- Which tab holds the removed workspace: the pane's tab, else the one in that directory.
                  local function tab_for_workspace(cx, root, pane)
                    if pane ~= nil then
                      local from_pane = cx.session:tab_of(pane)
                      if from_pane ~= nil then
                        return from_pane
                      end
                    end
                    for _, info in ipairs(cx.session:tabs()) do
                      if info.cwd == root then
                        return info.id
                      end
                    end
                    return nil
                  end

                  -- A tab is named repo/workspace.
                  local function tab_name(root, name)
                    local main_root = main_root_of(root)
                    if main_root == nil then
                      return name
                    end
                    return repo_name(main_root) .. "/" .. name
                  end

                  local function open_in(cx, root, name, created)
                    table.insert(reports, { open = { root = root, name = name, created = created } })
                  end

                  local function rollback(cx, main_root, name, root)
                    local function forget()
                      jj({
                        "jj",
                        "--no-pager",
                        "--ignore-working-copy",
                        "-R",
                        main_root,
                        "workspace",
                        "forget",
                        name,
                      }, function(result)
                        if result.status ~= 0 then
                          failed(cx, "forgetting " .. name, result)
                          return
                        end
                        if tern.fs.exists(root) then
                          tern.fs.remove(root)
                        end
                        warn(cx, "error", "could not open a tab, so " .. name .. " was rolled back")
                      end)
                    end

                    if not createBookmark then
                      forget()
                      return
                    end

                    jj({
                      "jj",
                      "--no-pager",
                      "--ignore-working-copy",
                      "-R",
                      main_root,
                      "bookmark",
                      "forget",
                      name,
                    }, function()
                      forget()
                    end)
                  end

                  -- cx:pick and cx:prompt draw over the focused pane
                  -- themselves; a :next callback gets a fresh cx as
                  -- its third argument, and nil as its result when
                  -- the user dismissed the picker or field.
                  local function ask_prompt(cx, req, cb)
                    cx:prompt({ placeholder = req.placeholder }):next(
                      function(text, _err, live)
                        if live == nil then
                          return
                        end
                        if text == nil then
                          cb(live, "cancel", nil)
                          return
                        end
                        cb(live, "ok", text)
                      end
                    )
                  end

                  local function ask_pick(cx, req, cb)
                    local items = {}
                    for _, item in ipairs(req.items or {}) do
                      table.insert(items, {
                        label = item.name,
                        detail = item.change .. "  "
                          .. (item.root == "" and "no checkout" or item.root),
                        current = item.root ~= "" and item.root == req.current or nil,
                        icon = "branch",
                        -- Ride along so the :next callback reads
                        -- them directly, no second lookup.
                        name = item.name,
                        change = item.change,
                        root = item.root,
                      })
                    end

                    cx:pick({ items = items }):next(
                      function(choice, _err, live)
                        if live == nil then
                          return
                        end
                        if choice == nil then
                          return
                        end
                        cb(live, "ok", choice)
                      end
                    )
                  end

                  local function list_workspaces(main_root, cb)
                    jj({
                      "jj",
                      "--no-pager",
                      "--ignore-working-copy",
                      "-R",
                      main_root,
                      "workspace",
                      "list",
                      "-T",
                      'name ++ "\\t" ++ target.change_id().shortest(12) ++ "\\t" ++ target.description().first_line() ++ "\\n"',
                    }, function(result)
                      if result.status ~= 0 then
                        cb(false, nil)
                        return
                      end

                      local items = {}
                      for _, line in ipairs(lines(result.stdout)) do
                        local name, change = string.match(line, "([^\t]*)\t([^\t]*)")
                        if name ~= nil and name ~= "" then
                          table.insert(items, { name = name, change = change, root = "" })
                        end
                      end

                      local index = 0
                      local function step()
                        index = index + 1
                        local item = items[index]
                        if item == nil then
                          cb(true, items)
                          return
                        end
                        jj({
                          "jj",
                          "--no-pager",
                          "--ignore-working-copy",
                          "-R",
                          main_root,
                          "workspace",
                          "root",
                          "--name",
                          item.name,
                        }, function(root_result)
                          local root = trim(root_result.stdout)
                          item.root = root_result.status == 0 and root or ""
                          step()
                        end)
                      end
                      step()
                    end)
                  end

                local function step_after_add(cx, main_root, name, root, checkout)
                  open_in(cx, checkout, name, true)
                end

                local function create(cx, cwd)
                  ask_prompt(cx, { placeholder = "workspace name" }, function(cx, action, name)
                    if action ~= "ok" or name == nil or name == "" then
                      return
                    end
                    if not valid_name(name) then
                      warn(cx, "error", "workspace name must match [A-Za-z0-9._/-]", tostring(name))
                      return
                    end

                    jj({ "jj", "--no-pager", "--ignore-working-copy", "-R", cwd, "workspace", "root" }, function(root_result)
                      local root = trim(root_result.stdout)
                      if root_result.status ~= 0 or root == "" then
                        warn(cx, "error", "not a jj workspace", cwd)
                        return
                      end
                      local main_root = main_root_of(root)
                      if main_root == nil then
                        warn(cx, "error", "could not find the main jj workspace", root)
                        return
                      end

                      list_workspaces(main_root, function(ok, items)
                        if not ok then
                          return
                        end
                        for _, item in ipairs(items) do
                          if item.name == name then
                            warn(cx, "error", "jj workspace already exists", name)
                            return
                          end
                        end

                        local checkout = workspaceRoot .. "/" .. repo_name(main_root) .. "/" .. slug(name)
                        if tern.fs.exists(checkout) then
                          warn(cx, "error", "checkout path already exists", checkout)
                          return
                        end

                        jj({
                          "jj",
                          "--no-pager",
                          "--ignore-working-copy",
                          "-R",
                          main_root,
                          "git",
                          "fetch",
                        }, { timeout_ms = 300000 }, function(fetch_result)
                          if fetch_result.status ~= 0 then
                            warn(cx, "info", "fetch failed, using the local change", trim(fetch_result.stderr))
                          end

                          jj({ "mkdir", "-p", "--", checkout }, function(mkdir_result)
                            if mkdir_result.status ~= 0 then
                              warn(cx, "error", "could not create " .. checkout, trim(mkdir_result.stderr))
                              return
                            end

                            jj({
                              "jj",
                              "--no-pager",
                              -- No --ignore-working-copy: this one updates a working copy
                              "-R",
                              main_root,
                              "workspace",
                              "add",
                              "--name",
                              name,
                              "--revision",
                              -- heads(trunk() | root()) not @, so a repository with no trunk starts at its root.
                              "heads(trunk() | root())",
                              checkout,
                            }, function(add_result)
                              if add_result.status ~= 0 then
                                failed(cx, "jj workspace add " .. name, add_result)
                                return
                              end

                              if not createBookmark then
                                step_after_add(cx, main_root, name, root, checkout)
                                return
                              end

                              jj({
                                "jj",
                                "--no-pager",
                                "--ignore-working-copy",
                                "-R",
                                checkout,
                                "bookmark",
                                "create",
                                name,
                                "--revision",
                                "@",
                              }, function(bookmark_result)
                                if bookmark_result.status ~= 0 then
                                  failed(cx, "jj bookmark create " .. name, bookmark_result)
                                end
                                step_after_add(cx, main_root, name, root, checkout)
                              end)
                            end)
                          end)
                        end)
                      end)
                    end)
                  end)
                end

                local function open(cx, cwd)
                  jj({
                    "jj",
                    "--no-pager",
                    "--ignore-working-copy",
                    "-R",
                    cwd,
                    "workspace",
                    "root",
                  }, function(root_result)
                    local root = trim(root_result.stdout)
                    if root_result.status ~= 0 or root == "" then
                      warn(cx, "error", "not a jj workspace", cwd)
                      return
                    end
                    local main_root = main_root_of(root)
                    if main_root == nil then
                      warn(cx, "error", "could not find the main jj workspace", root)
                      return
                    end

                    list_workspaces(main_root, function(ok, items)
                      if not ok then
                        warn(cx, "error", "jj workspace list failed", main_root)
                        return
                      end
                      if #items == 0 then
                        warn(cx, "info", "no jj workspaces", main_root)
                        return
                      end

                      table.insert(reports, { pick = { items = items, main_root = main_root, current = root } })
                    end)
                  end)
                end

                  local function remove(cx, cwd)
                    ask_prompt(cx, { placeholder = "remove this jj workspace?" }, function(cx, action)
                      if action ~= "ok" then
                        return
                      end

                      jj({
                        "jj",
                        "--no-pager",
                        "--ignore-working-copy",
                        "-R",
                        cwd,
                        "workspace",
                        "root",
                      }, function(root_result)
                        local root = trim(root_result.stdout)
                        if root_result.status ~= 0 or root == "" then
                          warn(cx, "error", "not a jj workspace", cwd)
                          return
                        end
                        local main_root = main_root_of(root)
                        if main_root == nil then
                          warn(cx, "error", "could not find the main jj workspace", root)
                          return
                        end
                        if main_root == root then
                          warn(cx, "error", "refusing to remove the main jj workspace", root)
                          return
                        end

                        jj({
                          "jj",
                          "--no-pager",
                          "--ignore-working-copy",
                          "-R",
                          root,
                          "workspace",
                          "list",
                          "-T",
                          'if(target.current_working_copy(), name ++ "\\n", "")',
                        }, function(name_result)
                          local name = trim(name_result.stdout)
                          if name_result.status ~= 0 or name == "" then
                            warn(cx, "error", "could not identify the current jj workspace", root)
                            return
                          end

                          jj({
                            "jj",
                            "--no-pager",
                            "--ignore-working-copy",
                            "-R",
                            root,
                            "status",
                          }, function(status_result)
                            if status_result.status ~= 0 then
                              failed(cx, "jj status", status_result)
                              return
                            end

                            jj({
                              "jj",
                              "--no-pager",
                              "--ignore-working-copy",
                              "-R",
                              main_root,
                              "workspace",
                              "forget",
                              name,
                            }, function(forget_result)
                              if forget_result.status ~= 0 then
                                failed(cx, "jj workspace forget " .. name, forget_result)
                                return
                              end

                              -- Queued rather than closed: a jj callback's cx is dead.
                              tabs[root] = nil
                              inflight = inflight + 1
                              table.insert(reports, { close_tab = { root = root, pane = pane } })

                              if not tern.fs.exists(root) then
                                warn(cx, "success", "forgot " .. name)
                                return
                              end

                              tern.process.run({ "rm", "-rf", "--", root }, { timeout_ms = 300000 }, function(rm_result)
                                if rm_result.status ~= 0 then
                                  warn(cx, "error", "forgot " .. name .. ", but could not delete its checkout", root)
                                  return
                                end
                                warn(cx, "success", "removed " .. name, root)
                              end)
                            end)
                          end)
                        end)
                      end)
                    end)
                  end

                  local cache = {}

                  local function status_of(pane)
                    if pane.cwd == nil or pane.cwd == "" then
                      return nil
                    end
                    local entry = cache[pane.cwd]
                    if type(entry) ~= "table" then
                      return nil
                    end

                    local segments = { { text = entry.change, icon = "branch" } }
                    for _, part in ipairs(entry.parts) do
                      table.insert(segments, part)
                    end
                    return segments
                  end

                  tern.chrome.status(status_of)

                  local function parse_status(cwd, text)
                    local conflict, empty, change, files, bookmarks = string.match(
                      text or "",
                      "^([^\x1f]*)\x1f([^\x1f]*)\x1f([^\x1f]*)\x1f([^\x1f]*)\x1f?(.*)$"
                    )
                    if change == nil or change == "" then
                      return nil
                    end

                    local parts = {}
                    if conflict == "1" then
                      table.insert(parts, { text = "!", tone = "error", icon = "alert" })
                    end
                    if empty ~= "1" then
                      table.insert(parts, { text = "*" .. files, tone = "muted", icon = "file" })
                    end
                    if bookmarks ~= nil and bookmarks ~= "" then
                      return { change = bookmarks, parts = parts, cwd = cwd }
                    end
                    return { change = "@" .. change, parts = parts, cwd = cwd }
                  end

                  local function read_status(cwd, cb)
                    jj({
                      "jj",
                      "--no-pager",
                      "--ignore-working-copy",
                      "-R",
                      cwd,
                      "log",
                      "--no-graph",
                      "--revisions",
                      "@",
                      "--template",
                      STATUS_TEMPLATE,
                    }, function(result)
                      if result.status ~= 0 then
                        cb(nil)
                        return
                      end
                      cb(parse_status(cwd, trim(result.stdout)))
                    end)
                  end

                  local function revset_count(cwd, revset, cb)
                    jj({
                      "jj",
                      "--no-pager",
                      "--ignore-working-copy",
                      "-R",
                      cwd,
                      "log",
                      "--count",
                      "--revisions",
                      revset,
                    }, function(result)
                      cb(tonumber(trim(result.stdout)))
                    end)
                  end

                  local function with_distance(entry, names, index, done)
                    if index > #names then
                      done()
                      return
                    end
                    local name = names[index]
                    if name == nil or not string.match(name, "^[%w._/%-]+$") then
                      with_distance(entry, names, index + 1, done)
                      return
                    end

                    revset_count(entry.cwd, name .. "@" .. statusRemote .. ".." .. name, function(ahead)
                      revset_count(entry.cwd, name .. ".." .. name .. "@" .. statusRemote, function(behind)
                        local distance = ""
                        if (ahead or 0) > 0 then
                          distance = distance .. "+" .. ahead
                        end
                        if (behind or 0) > 0 then
                          distance = distance .. "-" .. behind
                        end
                        if distance ~= "" then
                          table.insert(entry.parts, 1, { text = distance, tone = "muted", icon = "arrow-right" })
                        end
                        with_distance(entry, names, index + 1, done)
                      end)
                    end)
                  end

                  local function refresh_status(cx)
                    local cwds = {}
                    for _, pane in ipairs(cx.session:panes()) do
                      if pane.cwd ~= nil and pane.cwd ~= "" and cache[pane.cwd] == nil then
                        table.insert(cwds, pane.cwd)
                      end
                    end
                    if #cwds == 0 then
                      return
                    end

                    local index = 0
                    local function step()
                      index = index + 1
                      local cwd = cwds[index]
                      if cwd == nil then
                        tern.chrome.refresh()
                        return
                      end
                      read_status(cwd, function(entry)
                        if entry == nil then
                          step()
                          return
                        end
                        cache[cwd] = entry
                        local names = {}
                        for name in string.gmatch(entry.change, "%S+") do
                          table.insert(names, name)
                        end
                        with_distance(entry, names, 1, step)
                      end)
                    end
                    step()
                  end

                  local function focused_cwd(cx)
                    local pane = cx.session:focused()
                    if pane == nil then
                      return nil
                    end
                    local info = cx.session:pane(pane)
                    if info == nil or info.cwd == nil or info.cwd == "" then
                      return nil
                    end
                    return info.cwd
                  end

                  -- Declared here with the queue: a command's queued work has no event of its own.
                  local pump

                  local function jj_command(id, title, icon, run)
                    tern.command({
                      id = id,
                      title = title,
                      icon = icon,
                      group = "tern-jj",
                      available = function(cx)
                        return focused_cwd(cx) ~= nil
                      end,
                      run = function(cx)
                        local cwd = focused_cwd(cx)
                        if cwd == nil then
                          cx:toast("error", "the focused pane has no directory")
                          return
                        end
                        run(cx, cwd)
                        pump(cx)
                      end,
                    })
                  end

                  jj_command("create", "jj: new workspace", "branch", create)
                  jj_command("open", "jj: open workspace", "branch", open)
                  jj_command("remove", "jj: remove workspace", "branch", remove)

                  tern.command({
                    id = "refresh-status",
                    title = "jj: refresh status",
                    icon = "refresh",
                    group = "tern-jj",
                    run = function(cx)
                      refresh_status(cx)
                      pump(cx)
                    end,
                  })

                  -- f9 and o are not ours: tern silently drops a bind whose chord is taken.
                  tern.bind("ctrl+alt+shift+j", "plugin.jj.create")
                  tern.bind("ctrl+alt+shift+f10", "plugin.jj.open")
                  tern.bind("ctrl+alt+shift+r", "plugin.jj.remove")
                  tern.bind("ctrl+alt+shift+f8", "plugin.jj.refresh-status")

                  -- Carries out what the last jj run queued; bounded, since a continuation may queue more.
                  local function flush(cx)
                    for _ = 1, 32 do
                      if #reports == 0 then
                        return
                      end
                      local queued = reports
                      reports = {}

                      for _, report in ipairs(queued) do
                        if report.pick ~= nil then
                          inflight = inflight + 1
                          ask_pick(cx, {
                            items = report.pick.items,
                            current = report.pick.current,
                          }, function(answer_cx, _action, choice)
                            if choice == nil then
                              return
                            end
                            if choice.root == "" then
                              warn(answer_cx, "error", "no checkout for " .. choice.name, "the workspace has no directory")
                              return
                            end
                            open_in(answer_cx, choice.root, choice.name)
                          end)
                        elseif report.refresh ~= nil then
                          inflight = inflight - 1
                          refresh_status(cx)
                        elseif report.close_tab ~= nil then
                          inflight = inflight - 1
                          local tab = tab_for_workspace(cx, report.close_tab.root, report.close_tab.pane)
                          if tab == nil then
                            tern.log.info("tern-jj: no tab held the removed workspace", report.close_tab.root)
                          else
                            close_tab(cx, tab)
                          end
                        elseif report.jj_next ~= nil then
                          inflight = inflight - 1
                          report.jj_next(report.result)
                        elseif report.open ~= nil then
                          -- Only the pick path owes a decrement: it added one when it queued its dialog.
                          -- A create's count is consumed by `jj_next`; getting this wrong left the pump settling every 120 ms.
                          if not report.open.created then
                            inflight = inflight - 1
                          end

                          local root = report.open.root
                          local name = report.open.name

                          local tab = tabs[root]
                          if tab ~= nil and focus_tab(cx, tab) then
                            show(cx, "info", "focused " .. name, root)
                          else
                            -- new_tab takes a launch that carries no name, and answers with its pane, not its tab.
                            local label = tab_name(root, name)
                            local opened = cx.layout:new_tab({ cwd = root })
                            local tab = opened ~= nil and cx.session:tab_of(opened) or nil
                            if tab ~= nil then
                              cx.layout:name_tab(tab, label)
                            end
                            if opened == nil then
                              if report.open.created then
                                local main_root = main_root_of(root)
                                if main_root ~= nil then
                                  rollback(cx, main_root, name, root)
                                else
                                  show(cx, "error", "could not open a tab for " .. name, root)
                                end
                              else
                                show(cx, "error", "could not open a tab for " .. name, root)
                              end
                            else
                              tabs[root] = tab

                              -- post_create first, while the tab is one pane, so the layout's splits
                              -- inherit its setup. Typed straight away: a fresh pane's pty buffers
                              -- input, and a settle has no command to wait for, so it burns its 30 s.
                              if postCreate ~= "" then
                                cx:run(opened, postCreate .. "\r")
                              end

                              -- `opened` is the new pane id, which is what split takes.
                              if ideLayoutEnabled then
                                -- Its own continuation: every `:next` runs as the `await` hook in a
                                -- 50 ms budget, and sharing a callback tripped "await exceeded 50 ms".
                                tern.sleep(0):next(function(_, _, idle)
                                  if idle == nil then
                                    return
                                  end
                                  if not ide_layout_apply(idle, opened) then
                                    warn(idle, "error", "could not lay out " .. name)
                                  end
                                  pump(idle)
                                end)
                              end
                              show(cx, "success", "opened " .. name, root)
                            end
                          end
                        else
                          show(cx, report.level, report.text, report.sub)
                        end
                      end
                    end
                  end

                  -- The pump: it keeps the chain going without a clock
                  pump = function(cx)
                    flush(cx)

                    -- On `inflight`, not the queue: a step that spawned the next one keeps it alive
                    if inflight == 0 then
                      return
                    end
                    local pane = cx.session:focused()
                    if pane == nil then
                      return
                    end
                    cx.session:settle(pane, 120):next(function(_, _, live)
                      if live ~= nil then
                        pump(live)
                      end
                    end)
                  end

                  tern.on("title", function(_ev, cx)
                    pump(cx)
                  end)

                  -- Queued: the focus hook's 50 ms budget cannot cover refresh_status spawning jj.
                  tern.on("focus", function(ev, cx)
                    inflight = inflight + 1
                    table.insert(reports, { refresh = true })
                    pump(cx)
                  end)
              '';

          # The manifest's entry: the window half exceeds the load hook's budget, so the entry compiles it with loadstring on the first tick, and needs no timer.
          entry =
            pkgs.writers.writeText "tern-jj-entry.luau" # luau
              ''
                -- !nonstrict
                local body = loadstring(tern.fs.read("window.luau"))

                if type(body) ~= "function" then
                  tern.log.error("tern-jj: window.luau did not compile")
                  return
                end

                local started = false
                tern.timer(1, function()
                  if started then
                    return
                  end
                  started = true
                  body()
                end)
              '';

        in
        pkgs.runCommand "tern-jj-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
          ln --symbolic ${window} "$out/window.luau"
        '';
    };
}
