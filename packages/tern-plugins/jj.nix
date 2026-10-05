{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.lib) toJSON;

      # Inlined into the window half: a hook's budget is too small for a file read; new checkouts land in <workspace_root>/<repo>/<workspace-slug>
      settings = {
        workspace_root = "~/projects/tern-worktrees";
        create_bookmark = false;
        post_create = "try {direnv allow}";

        post_create_actions = [ "plugin.ide.layout" ];

        status_remote = "origin";
      };

      settingsLuau = ''
        local SETTINGS = {
          workspace_root = ${toJSON settings.workspace_root},
          create_bookmark = ${if settings.create_bookmark then "true" else "false"},
          post_create = ${toJSON settings.post_create},
          post_create_actions = { ${lib.concatMapStringsSep ", " toJSON settings.post_create_actions} },
          status_remote = ${toJSON settings.status_remote},
        }
      '';
    in
    {
      # tern-jj: Jujutsu workspace integration
      #   * create: fetch, a workspace on @, then a tab
      #   * open:   list workspaces, focus or add a tab
      #   * remove: snapshot, forget, delete the checkout
      #   * status: bookmarks or change id, plus !, *N and +N/-N
      packages.tern-jj-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-jj-plugin.toml" {
            schema = 1;
            id = "jj";
            name = "tern-jj";
            version = "0.1.0";
            description = "Create, open, remove and inspect Jujutsu workspaces from Tern.";
            icon = "branch";

            blocks = [
              {
                id = "dialog";
                title = "jj workspace";
                icon = "branch";
              }
            ];

            host = "host.luau";
            window = "init.luau";
          };

          host =
            pkgs.writers.writeText "tern-jj-host.luau" # luau
              ''
                -- !nonstrict
                local ui = tern.ui

                -- One keycap row per hint, the way Tern's own sheets write them
                local HINTS = {
                  prompt = {
                    { nil, "type the workspace name" },
                    { { "enter" }, "confirm" },
                    { { "esc" }, "cancel" },
                  },
                  pick = {
                    { { "up", "down" }, "choose" },
                    { { "enter" }, "open" },
                    { { "esc" }, "cancel" },
                  },
                  confirm = {
                    { { "enter" }, "confirm" },
                    { { "esc" }, "cancel" },
                  },
                }

                local function hints(mode)
                  local parts = {}
                  for _, entry in ipairs(HINTS[mode] or {}) do
                    if entry[1] ~= nil then
                      table.insert(parts, ui.node("kbd", { keys = entry[1] }))
                    end
                    table.insert(parts, ui.text({ t = entry[2], s = "muted" }))
                  end
                  return ui.row(parts)
                end

                local function field(line, index)
                  local at = 1
                  for _ = 1, index - 1 do
                    local next_at = string.find(line, "\t", at, true)
                    if next_at == nil then
                      return ""
                    end
                    at = next_at + 1
                  end
                  local stop = string.find(line, "\t", at, true)
                  if stop == nil then
                    return string.sub(line, at)
                  end
                  return string.sub(line, at, stop - 1)
                end

                local function request(args)
                  local head = args[1] or ""
                  local req = {
                    mode = field(head, 1),
                    title = field(head, 2),
                    message = field(head, 3),
                    items = {},
                  }
                  if req.mode == "prompt" then
                    req.placeholder = field(head, 4)
                  elseif req.mode == "pick" then
                    -- The workspace the asking pane is in, so its row reads current
                    req.current = field(head, 4)
                  end

                  for index = 2, #args do
                    table.insert(req.items, {
                      name = field(args[index], 1),
                      change = field(args[index], 2),
                      root = field(args[index], 3),
                    })
                  end
                  return req
                end

                local function item_named(req, name)
                  for _, item in ipairs(req.items) do
                    if item.name == name then
                      return item
                    end
                  end
                  return nil
                end

                -- The rows a pick request shows: the sheet's search line only draws
                -- the query, so filtering and the match offsets are ours. Offsets are
                -- UTF-16 in the protocol and workspace names are ASCII, so the byte
                -- offsets of string.find are the same numbers.
                local function catalog(state, req)
                  local query = string.lower(state.query)
                  local items, order = {}, {}
                  local current = nil

                  for _, item in ipairs(req.items) do
                    local label = item.name
                    local lower = string.lower(label)
                    local at = nil
                    if query ~= "" then
                      at = string.find(lower, query, 1, true)
                      if at == nil then
                        at = string.find(string.lower(item.change), query, 1, true)
                      end
                    end

                    if query == "" or at ~= nil then
                      local hits = nil
                      if at ~= nil and string.find(lower, query, 1, true) ~= nil then
                        hits = { { at - 1, at - 1 + #query } }
                      end

                      table.insert(items, {
                        id = label,
                        label = label,
                        detail = item.root == "" and "no checkout" or item.root,
                        mono = true,
                        icon = "branch",
                        tone = item.root == "" and "muted" or nil,
                        disabled = item.root == "" and "this workspace has no checkout" or nil,
                        hits = hits,
                        facts = { change = item.change },
                      })
                      table.insert(order, label)
                      if item.root ~= "" and item.root == req.current then
                        current = label
                      end
                    end
                  end

                  return items, order, current
                end

                local function in_order(order, name)
                  for _, listed in ipairs(order) do
                    if listed == name then
                      return true
                    end
                  end
                  return false
                end

                -- The answer the window half reads out of the block's title
                local function submit(state, answer)
                  state.answered = true
                  state.answer = answer
                end

                tern.block.define("dialog", {
                  init = function(cx, args, saved)
                    local req = request(args)
                    local selected = nil
                    for _, item in ipairs(req.items) do
                      if item.root ~= "" and item.root == req.current then
                        selected = item.name
                      end
                    end
                    for _, item in ipairs(req.items) do
                      if selected == nil and item.root ~= "" then
                        selected = item.name
                      end
                    end
                    if selected == nil and req.items[1] ~= nil then
                      selected = req.items[1].name
                    end

                    return {
                      req = req,
                      buffer = "",
                      cursor = 0,
                      query = "",
                      selected = selected,
                      answered = false,
                      focused = false,
                    }
                  end,

                  title = function(state)
                    if not state.answered then
                      return state.req and state.req.title or nil
                    end
                    return state.answer
                  end,

                  view = function(state, cx)
                    local req = state.req

                    if req.mode == "pick" then
                      local items, order, current = catalog(state, req)
                      if state.selected == nil or not in_order(order, state.selected) then
                        state.selected = order[1]
                      end

                      return {
                        main = ui.col({ ui.text({ t = req.title, s = "strong" }) }),
                        layer = ui.col({
                          ui.node("picker", {
                            key = "picker",
                            size = "md",
                            icon = "branch",
                            title = req.title,
                            subtitle = req.message ~= "" and req.message or nil,
                            noun = "workspaces",
                            query = state.query,
                            cursor = #state.query,
                            items = items,
                            order = order,
                            selected = state.selected,
                            current = current ~= nil and { current } or {},
                            columns = { { id = "change", head = "change", format = "dim", priority = 50 } },
                            empty = { ui.span("No jj workspaces match", "muted") },
                            total = #req.items,
                            preview = "none",
                            actions = {
                              { id = "close", label = "Cancel", keys = { "esc" } },
                              { id = "open", label = "Open", keys = { "enter" }, primary = true },
                            },
                          }),
                        }),
                      }
                    end

                    local parts = { ui.text({ t = req.title, s = "strong" }) }
                    if req.message ~= "" then
                      table.insert(parts, ui.text({ t = req.message, s = "muted" }))
                    end

                    if req.mode == "prompt" then
                      table.insert(
                        parts,
                        ui.node("input", {
                          key = "name",
                          text = state.buffer,
                          cursor = state.cursor,
                          placeholder = req.placeholder,
                          prompt = { ui.span("› ", "muted") },
                        })
                      )

                      -- The caret blinks only on the field the surface has focused
                      if not state.focused then
                        state.focused = true
                        cx:frame({ { "focus", "main.name" } })
                      end
                    end

                    table.insert(parts, hints(req.mode))
                    return { main = ui.col(parts) }
                  end,

                  key = function(state, key, cx)
                    local req = state.req
                    if state.answered then
                      return false
                    end

                    if key.name == "escape" then
                      submit(state, "cancel")
                      return true
                    end

                    if key.name == "enter" and not key.shift then
                      if req.mode == "pick" then
                        submit(state, "ok:" .. (state.selected or ""))
                      elseif req.mode == "prompt" then
                        submit(state, "ok:" .. state.buffer)
                      else
                        submit(state, "ok:")
                      end
                      return true
                    end

                    if req.mode == "pick" then
                      local _, order = catalog(state, req)
                      local count = #order
                      if key.name == "up" or key.name == "down" then
                        if count == 0 then
                          return false
                        end
                        local index = 1
                        for position, listed in ipairs(order) do
                          if listed == state.selected then
                            index = position
                          end
                        end
                        if key.name == "up" then
                          index = (index - 2) % count + 1
                        else
                          index = index % count + 1
                        end
                        state.selected = order[index]
                        return true
                      end
                      if key.name == "backspace" then
                        state.query = string.sub(state.query, 1, math.max(0, #state.query - 1))
                        state.selected = nil
                        return true
                      end
                      if key.text ~= nil and not (key.ctrl or key.meta) then
                        state.query = state.query .. key.text
                        state.selected = nil
                        return true
                      end
                      return false
                    end

                    if req.mode == "prompt" then
                      if key.name == "backspace" then
                        if state.cursor > 0 then
                          state.buffer = string.sub(state.buffer, 1, state.cursor - 1)
                            .. string.sub(state.buffer, state.cursor + 1)
                          state.cursor = state.cursor - 1
                        end
                        return true
                      end
                      if key.name == "left" then
                        state.cursor = math.max(0, state.cursor - 1)
                        return true
                      end
                      if key.name == "right" then
                        state.cursor = math.min(#state.buffer, state.cursor + 1)
                        return true
                      end
                      if key.name == "home" then
                        state.cursor = 0
                        return true
                      end
                      if key.name == "end" then
                        state.cursor = #state.buffer
                        return true
                      end
                      if key.text ~= nil and not (key.ctrl or key.meta) then
                        state.buffer = string.sub(state.buffer, 1, state.cursor)
                          .. key.text
                          .. string.sub(state.buffer, state.cursor + 1)
                        state.cursor = state.cursor + #key.text
                        return true
                      end
                    end

                    return false
                  end,

                  -- Pointer input: the sheet's rows, its action bar, and a click
                  -- into the name field
                  event = function(state, ev, cx)
                    if state.answered then
                      return
                    end

                    if ev.ev == "select" or ev.ev == "activate" then
                      if type(ev.item) == "string" and item_named(state.req, ev.item) ~= nil then
                        state.selected = ev.item
                      end
                      if ev.ev == "activate" then
                        submit(state, "ok:" .. (state.selected or ""))
                      end
                      return
                    end

                    if ev.ev == "action" then
                      if ev.act == "close" then
                        submit(state, "cancel")
                      elseif ev.act == "open" then
                        submit(state, "ok:" .. (state.selected or ""))
                      end
                      return
                    end

                    if ev.ev == "focus" then
                      cx:frame({ { "focus", ev.id } })
                    end
                  end,
                })
              '';

          window =
            pkgs.writers.writeText "tern-jj-window.luau" # luau
              ''
                  -- !nonstrict
                  local ui = tern.ui

                  ${settingsLuau}

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
                  local postCreateActions = SETTINGS.post_create_actions
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

                  -- A workspace owns its tab: closing one pane leaves an empty tab behind, so every pane of that tab goes
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

                  -- The tab holding the removed workspace: the focused pane's tab, else the one in that directory
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

                  -- A tab is named repo/workspace, so tabs of one repository read together and two workspaces of the same name stay apart
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

                  local waiting = nil

                  local function ask(cx, req, cb)
                    local args = { req.mode .. "\t" .. req.title .. "\t" .. (req.message or "") }
                    if req.mode == "prompt" then
                      args[1] = args[1] .. "\t" .. (req.placeholder or "")
                    elseif req.mode == "pick" then
                      -- The checkout the asking pane is in: the sheet marks its row
                      args[1] = args[1] .. "\t" .. (req.current or "")
                    end
                    for _, item in ipairs(req.items or {}) do
                      table.insert(args, item.name .. "\t" .. (item.change or "") .. "\t" .. (item.root or ""))
                    end

                    -- Beside the focused block, then floated over it: the dialog is
                    -- an overlay, so the tab and its layout stay as they were.
                    local pane = cx:new_block("jj.dialog", args, "beside", { focus = false })
                    if pane == nil then
                      warn(cx, "error", "the jj dialog block is not available", "no Ready plugin defines jj.dialog")
                      return
                    end

                    local floated, err = cx.layout:float(pane)
                    if not floated then
                      cx.layout:close(pane)
                      warn(cx, "error", "could not overlay the jj dialog", err)
                      return
                    end

                    -- A new overlay is a glance: focusing it expands it, so keys
                    -- reach the dialog.
                    cx.layout:focus(pane)
                    waiting = { pane = pane, cb = cb }
                  end

                  -- The block's title is the answer: "cancel" or "ok:<value>"
                  local function answer(cx, pane, title)
                    if waiting == nil or waiting.pane ~= pane then
                      return
                    end
                    if title ~= "cancel" and string.sub(title, 1, 3) ~= "ok:" then
                      return
                    end

                    local cb = waiting.cb
                    waiting = nil

                    cx.layout:close(pane)

                    cb(cx, title == "cancel" and "cancel" or "ok", title == "cancel" and nil or string.sub(title, 4))
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
                  ask(cx, {
                    mode = "prompt",
                    title = "new jj workspace",
                    placeholder = "workspace name",
                  }, function(cx, action, name)
                    if action ~= "ok" then
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
                              -- heads(trunk() | root()), not @: a new worktree starts from the trunk, and a repository without one starts from its root
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
                    local pane = cx.session:focused()
                    ask(cx, {
                      mode = "confirm",
                      title = "remove jj workspace",
                    }, function(cx, action)
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

                              -- Queued, not closed: the workspace is gone so its tab goes too, and a jj callback's cx is dead
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

                  -- Defined with the queue, further down: every command starts it, since work a command queues has no event of its own to drain it
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

                  -- f9 and o are NOT ours and must stay that way: f9 is tern-ide's plugin.ide.layout and tmux owns o; tern silently drops a bind whose chord is taken
                  tern.bind("ctrl+alt+shift+j", "plugin.jj.create")
                  tern.bind("ctrl+alt+shift+f10", "plugin.jj.open")
                  tern.bind("ctrl+alt+shift+r", "plugin.jj.remove")
                  tern.bind("ctrl+alt+shift+f8", "plugin.jj.refresh-status")

                  -- Carry out what the last jj run queued: a toast, a tab, or the next step. Bounded, since a continuation may queue more work
                  local function flush(cx)
                    for _ = 1, 32 do
                      if #reports == 0 then
                        return
                      end
                      local queued = reports
                      reports = {}

                      for _, report in ipairs(queued) do
                        if report.run_action ~= nil then
                          inflight = inflight - 1

                          local ok, err = pcall(cx.action, cx, report.run_action)
                          if not ok then
                            tern.log.warn("tern-jj: action failed", report.run_action, err)
                            show(cx, "error", "could not run " .. report.run_action)
                          end
                        elseif report.pick ~= nil then
                          inflight = inflight + 1
                          ask(cx, {
                            mode = "pick",
                            title = "open jj workspace",
                            message = report.pick.main_root,
                            items = report.pick.items,
                            current = report.pick.current,
                          }, function(answer_cx, action, picked)
                            if action ~= "ok" then
                              return
                            end
                            for _, item in ipairs(report.pick.items) do
                              if item.name == picked then
                                if item.root == "" then
                                  warn(answer_cx, "error", "no checkout for " .. picked, "the workspace has no directory")
                                  return
                                end
                                open_in(answer_cx, item.root, picked)
                                return
                              end
                            end
                            warn(answer_cx, "error", "no jj workspace named " .. tostring(picked))
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
                          local root = report.open.root
                          local name = report.open.name

                          local tab = tabs[root]
                          if tab ~= nil and focus_tab(cx, tab) then
                            show(cx, "info", "focused " .. name, root)
                          else
                            -- new_tab takes a launch, which carries no name, and answers with its pane, not its tab
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
                              if postCreate ~= "" then
                                -- Waits for the pane's shell to reach a prompt
                                for _, info in ipairs(cx.session:tabs()) do
                                  if info.id == opened then
                                    cx.session:settle(info.pane, 30000):next(function(_, _, live)
                                      if live ~= nil then
                                        live:run(info.pane, postCreate .. "\r")
                                      end
                                    end)
                                    break
                                  end
                                end
                              end

                              -- Any tern action, in order, after the shell command
                              for _, action in ipairs(postCreateActions or {}) do
                                inflight = inflight + 1
                                table.insert(reports, { run_action = action })
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

                  tern.on("title", function(ev, cx)
                    answer(cx, ev.pane, ev.title)
                    pump(cx)
                  end)

                  -- Queued, not called: a focus hook has a 50 ms budget and refresh_status spawns jj, so calling it here tripped "focus exceeded 50 ms" and disabled the handler
                  tern.on("focus", function(ev, cx)
                    inflight = inflight + 1
                    table.insert(reports, { refresh = true })
                    pump(cx)
                  end)
              '';

          # The manifest's entry. Short on purpose: the window half exceeds the load hook's budget, so the entry compiles it with loadstring and runs it on the first tick. No recurring timer, since nothing in this plugin needs a clock
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
          ln --symbolic ${host} "$out/host.luau"
          ln --symbolic ${entry} "$out/init.luau"
          ln --symbolic ${window} "$out/window.luau"
        '';
    };
}
