# The window half of the jj plugin. outputs.nix skips any path holding
# "/_", so this file is not pulled into the flake's module tree.
{
  # The window half of tern-jj.
  #
  # It keeps the work that only the window can do: the chrome formatter,
  # the palette commands, the pickers and the tab work. It does no disk
  # work, no process work and no daemon IPC inside a 4 ms hook, because
  # the window's UI thread has 4 ms for a formatter and 50 ms for
  # everything else, and a call made from inside another call keeps the
  # outer call's deadline.
  #
  # The host half owns the jj CLI, the status refresh and the workspace
  # work. The window asks it for work and reads the status map it
  # publishes.
  #
  # `settings` is the settings Luau; `channel` is the shared transport;
  # `ideLayout` and `stepped` are the shared layout helpers.
  jjWindow =
    {
      settings,
      channel,
      ideLayout,
      stepped,
    }:
    # luau
    ''
      -- !nonstrict
      ${settings}

      ${channel}

      ${ideLayout}

      ${stepped}

      -- The status of every directory the host knows: directory ->
      -- segments. The formatter reads this table and nothing else, so it
      -- costs a table lookup under its 4 ms budget.
      local cache = {}

      -- The directory of the focused pane. The `available` check reads
      -- this and nothing else: it has 4 ms, and asking the daemon for
      -- the focused pane is an IPC round trip.
      local focused_cwd = nil

      -- The tabs this plugin opened, by workspace directory.
      local tabs = {}

      local function trim(text)
        return (string.gsub(text or "", "%s+$", ""))
      end

      -- A toast and a log line: one place, so every message looks the
      -- same.
      local function warn(cx, level, text, sub)
        tern.log.warn(text, sub)
        cx:toast(level, text, sub)
      end

      local channel = channel_window()

      -- The status formatter. A table lookup and nothing else.
      local function status_of(pane)
        if pane.cwd == nil or pane.cwd == "" then
          return nil
        end
        local entry = cache[pane.cwd]
        if type(entry) ~= "table" or entry.segments == nil then
          return nil
        end
        return entry.segments
      end

      tern.chrome.status(status_of)

      -- Copy the published status map into the local table.
      --
      -- The map is read in a timer, never in the formatter: a file read
      -- in the formatter would cost the UI thread the time the disk
      -- takes, and the formatter has 4 ms.
      --
      -- A refresh follows only when the map changed: a refresh forces a
      -- full redraw of every pane, which is what makes the next frame
      -- slow, and a slow frame is what trips the formatter.
      local function pull_status()
        local published = channel.published("status")
        if type(published) ~= "table" then
          return
        end

        local changed = false
        for cwd, entry in pairs(published) do
          local current = cache[cwd]
          if current == nil or current.change ~= entry.change or #current.segments ~= #entry.segments then
            changed = true
            break
          end
        end
        if not changed then
          for cwd in pairs(cache) do
            if published[cwd] == nil then
              changed = true
              break
            end
          end
        end
        if not changed then
          return
        end

        cache = published
        tern.chrome.refresh()
      end

      -- The picker and the prompt draw over the focused pane themselves.
      -- A :next callback gets a fresh cx as its third argument, and nil
      -- as its result when the user dismissed the picker or field.
      --
      -- The cx is a parameter, not a shared local: a picker that opens
      -- from a channel reply runs long after the command handler
      -- returned, and a local that the handler cleared on the way out
      -- would leave the picker without a window to draw on.
      local function cx_pick(cx: WindowCx, items, cb)
        cx:pick({ items = items }):next(function(choice, _err, live)
          if live == nil then
            return
          end
          cb(live, choice)
        end)
      end

      local function cx_prompt(cx: WindowCx, placeholder, cb)
        cx:prompt({ placeholder = placeholder }):next(function(text, _err, live)
          if live == nil then
            return
          end
          cb(text, live)
        end)
      end

      -- The picker over the workspaces. The items come from the host, so
      -- the window does no disk work to build them.
      local function ask_pick(cx: WindowCx, items, current, cb)
        local choices = {}
        for _, item in ipairs(items or {}) do
          table.insert(choices, {
            label = item.label or item.name,
            detail = item.change .. "  " .. (item.root == "" and "no checkout" or item.root),
            current = item.root ~= "" and item.root == current or nil,
            icon = "branch",
            -- Ride along so the callback reads them directly, no second
            -- lookup.
            name = item.name,
            change = item.change,
            root = item.root,
          })
        end

        cx_pick(cx, choices, cb)
      end

      -- The tab of a workspace: the one the plugin opened, else the one
      -- holding a pane in that directory.
      local function tab_for_workspace(cx, root)
        local known = tabs[root]
        if known ~= nil then
          return known
        end
        for _, info in ipairs(cx.session:tabs()) do
          if info.cwd == root then
            return info.id
          end
        end
        return nil
      end

      local function focus_tab(cx, tab)
        for _, info in ipairs(cx.session:tabs()) do
          if info.id == tab then
            cx.layout:focus(info.pane)
            return true
          end
        end
        return false
      end

      -- A workspace owns its tab: closing every pane of that tab takes
      -- the tab with it.
      --
      -- Closing is bounded to one hook pass: the 50 ms hook budget
      -- covers a handful of pane reads, and every cx.session call
      -- marshals IPC. One pass closes what went; the next event (a
      -- pane_closed fires as each pane goes) finishes the rest.
      local function close_tab(cx, tab)
        local leaves = {}
        for _, info in ipairs(cx.session:panes()) do
          if info.tab == tab then
            table.insert(leaves, info.pane)
          end
        end
        for _, pane in ipairs(leaves) do
          local ok, err = pcall(cx.layout.close, cx.layout, pane)
          if not ok then
            tern.log.info("tern-jj: pane already closed", pane, err)
          end
        end
        return #leaves > 0
      end

      -- Open a tab for a workspace and name it.
      --
      -- One step per pass: new_tab, the tab's name and the focus are
      -- three IPC round trips, and in one pass they share the command's
      -- 50 ms budget.
      local function open_workspace(cx, root, name, label, created)
        local state = { tab = nil, pane = nil }

        stepped({
          function(step_cx)
            local opened = step_cx.layout:new_tab({ cwd = root })
            if opened == nil then
              warn(step_cx, "error", "could not open a tab for " .. name, root)
              if created then
                -- The workspace exists but no tab holds it: undo it.
                channel.request_later("rollback", { action = "rollback", name = name }, function(_payload, _reply_cx)
                  warn(_reply_cx, "error", "could not open a tab, so " .. name .. " was rolled back")
                end)
              end
              return false
            end
            state.pane = opened
            return true
          end,
          function(step_cx)
            local tab = step_cx.session:tab_of(state.pane)
            if tab == nil then
              warn(step_cx, "error", "could not open a tab for " .. name, root)
              return false
            end
            state.tab = tab
            tabs[root] = tab
            step_cx.layout:name_tab(tab, label or name)
            return true
          end,
          function(step_cx)
            -- post_create first, while the tab is one pane, so the
            -- layout's splits inherit its setup. Typed straight away: a
            -- fresh pane's pty buffers input, and a settle has no
            -- command to wait for, so it burns its 30 s.
            if postCreate ~= "" and state.pane ~= nil then
              step_cx:run(state.pane, postCreate .. "\r")
            end
            return true
          end,
          function(step_cx)
            -- The IDE layout is a set of steps of its own, so it runs
            -- after this one, in its own passes.
            if ideLayoutEnabled and state.pane ~= nil then
              stepped(ide_layout_steps(state.pane), function(_cx, ok)
                if not ok then
                  warn(_cx, "error", "could not lay out " .. name)
                end
              end)
            end
            return true
          end,
        })
      end

      -- The commands. Their `available` check reads the cached focused
      -- directory, never the daemon: it has 4 ms, and the daemon is an
      -- IPC round trip away.
      --
      -- The run reads the directory itself when the cache has none.
      -- The cache is filled by a timer, and the timer may not have run
      -- yet, or may have run before the pane list named a focused
      -- pane. A command that gave up then would do nothing at all, and
      -- the user would see no error.
      local function focused_cwd_now(cx): string?
        if focused_cwd ~= nil then
          return focused_cwd
        end
        local ok, panes = pcall(function(): { PaneInfo }
          return cx.session:panes()
        end)
        if not ok or panes == nil then
          return nil
        end
        for _, pane in ipairs(panes) do
          if pane.focused == true and pane.cwd ~= nil and pane.cwd ~= "" then
            focused_cwd = pane.cwd
            return focused_cwd
          end
        end
        return nil
      end

      local function jj_command(id, title, icon, run)
        tern.command({
          id = id,
          title = title,
          icon = icon,
          group = "tern-jj",
          available = function(_cx)
            return focused_cwd ~= nil
          end,
          run = function(cx)
            local cwd = focused_cwd_now(cx)
            if cwd == nil then
              cx:toast("error", "the focused pane has no directory")
              return
            end
            run(cx, cwd)
          end,
        })
      end

      jj_command("create", "jj: new workspace", "branch", function(cx, cwd)
        cx_prompt(cx, "workspace name", function(prompt_cx, name)
          if name == nil or name == "" then
            return
          end
          channel.request_later("create", { action = "create", cwd = cwd, name = name }, function(payload, reply_cx)
            if payload == nil then
              return
            end
            if payload.error ~= nil then
              warn(reply_cx, "error", payload.error, payload.detail)
              return
            end
            if payload.note ~= nil and payload.note ~= "" then
              warn(reply_cx, "info", payload.note)
            end
            open_workspace(reply_cx, payload.root, payload.name, payload.label, payload.created)
          end)
        end)
      end)

      jj_command("open", "jj: open workspace", "branch", function(cx, cwd)
        channel.request_later("open", { action = "open", cwd = cwd }, function(payload, reply_cx)
          -- The debug line is the witness for a test harness: it says
          -- the command ran and the answer came back, and the default
          -- log filter drops it.
          tern.log.debug("tern-jj: the open request was answered with " .. tostring(payload and payload.items and #payload.items) .. " workspaces")
          if payload == nil then
            return
          end
          if payload.error ~= nil then
            warn(reply_cx, "error", payload.error, payload.detail)
            return
          end
          ask_pick(reply_cx, payload.items, payload.current, function(pick_cx, choice)
            if choice == nil then
              return
            end
            -- No checkout: the pick ends here.
            if choice.root == "" then
              warn(pick_cx, "error", "no checkout for " .. choice.name, "the workspace has no directory")
              return
            end
            open_workspace(pick_cx, choice.root, choice.name, choice.label, false)
          end)
        end)
      end)

      jj_command("remove", "jj: remove workspace", "branch", function(cx, cwd)
        -- The pane the command ran from: it holds the tab that the
        -- removal closes.
        local pane = cx.session:focused()
        cx_prompt(cx, "remove this jj workspace?", function(prompt_cx, text)
          if text == nil then
            return
          end
          channel.request_later("remove", { action = "remove", cwd = cwd }, function(payload, reply_cx)
            if payload == nil then
              return
            end
            if payload.error ~= nil then
              warn(reply_cx, "error", payload.error, payload.detail)
              return
            end
            if payload.removed ~= true then
              return
            end
            -- Close the tab that held the removed workspace.
            local tab = tab_for_workspace(reply_cx, payload.root)
            if tab == nil then
              local by_pane = nil
              if pane ~= nil then
                by_pane = reply_cx.session:tab_of(pane)
              end
              tab = by_pane
            end
            if tab == nil then
              tern.log.info("tern-jj: no tab held the removed workspace", payload.root)
            else
              close_tab(reply_cx, tab)
            end
            tabs[payload.root] = nil
            warn(reply_cx, "success", "removed " .. payload.name, payload.root)
          end)
        end)
      end)

      tern.command({
        id = "refresh-status",
        title = "jj: refresh status",
        icon = "refresh",
        group = "tern-jj",
        run = function(_cx)
          channel.request_later("refresh", { action = "refresh", force = true }, function(_payload, _reply_cx)
            pull_status()
          end)
        end,
      })

      -- f9 and o are not ours: tern silently drops a bind whose chord is
      -- taken.
      tern.bind("ctrl+alt+shift+j", "plugin.jj.create")
      tern.bind("ctrl+alt+shift+f10", "plugin.jj.open")
      tern.bind("ctrl+alt+shift+r", "plugin.jj.remove")
      tern.bind("ctrl+alt+shift+f8", "plugin.jj.refresh-status")

      -- The focused pane's directory.
      --
      -- The pane list says which pane is focused, and the list is the
      -- only source: the focus event names the pane too, but the two
      -- use different id spaces, and an id from one cannot be looked
      -- up in the other. The event is a trigger that makes the window
      -- read the list again.
      --
      -- The `available` check reads this and nothing else: it has
      -- 4 ms, and asking the daemon for the focused pane is an IPC
      -- round trip.
      local focus_changed = false
      tern.on("focus", function(_ev, _cx)
        focus_changed = true
      end)

      -- The window's own view of its panes. The host publishes the
      -- status by directory; the window knows which directory each of
      -- its panes is in, so the two meet here.
      --
      -- The panes are read in a timer, not in the formatter and not in
      -- the focus event: the formatter has 4 ms and the focus event 50,
      -- and a pane list is an IPC round trip.
      local function pull_panes(cx)
        local panes = cx.session:panes()
        local list_focused = nil
        for _, pane in ipairs(panes) do
          -- The pane list says which of its panes is focused.
          --
          -- The flag comes from the list rather than from
          -- `cx.session:focused()`, because the two use different id
          -- spaces: the list gives the plain pane ids, and
          -- `focused()` gives a session-qualified one. A lookup of the
          -- qualified id in a table of plain ids finds nothing.
          if pane.focused == true then
            list_focused = pane
          end
        end
        if list_focused ~= nil then
          -- The list is authoritative: it says which pane is focused
          -- now, and it names the directory itself.
          focused_cwd = list_focused.cwd
        else
          focused_cwd = nil
        end
      end

      -- The channel's timer: it drains the answers. The window half
      -- must run it, or a request never gets its answer and the split
      -- silently stops updating.
      --
      -- The poll does nothing else. The pane list is an IPC round trip
      -- and the status a file read, and a pass that did all three cost
      -- the UI thread more than its 50 ms budget: a hook that runs over
      -- its budget is disabled until the next reload, and the timer
      -- then fired every few seconds instead of every 200 ms. The two
      -- reads have their own timer below.
      channel.start(200, nil)

      -- The reads of the panes and of the status. They have their own
      -- timer, so the channel's pass stays cheap and the round trip
      -- stays quick.
      --
      -- A focus change moves the pane read ahead of its turn: the
      -- `available` check reads the focused directory, and a stale one
      -- hides the commands for the pane the user just moved to.
      local read_tick = 0
      local function read_tick_fn(cx)
        tern.timer(400, read_tick_fn)
        if cx == nil then
          return
        end
        read_tick += 1
        if focus_changed then
          focus_changed = false
          pull_panes(cx)
        elseif read_tick % 2 == 1 then
          pull_status()
        else
          pull_panes(cx)
        end
      end
      tern.timer(400, read_tick_fn)

      -- The first read of the panes. The timer fills the cache, but the
      -- timer waits for its first tick, and a command dispatched in
      -- that window would find no focused directory and do nothing.
      -- The read happens in the window half's own pass, which is the
      -- one that has the cx.
      tern.sleep(0):next(function(_result, _err, live)
        if live == nil then
          return
        end
        pull_panes(live)
      end)

      -- A refresh of the status map on demand, and the first read.
      channel.request_later("refresh", { action = "refresh" }, function(_payload, _reply_cx)
        pull_status()
      end)
    '';
}
