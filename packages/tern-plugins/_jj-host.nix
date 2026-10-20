# The host half of the jj plugin. outputs.nix skips any path holding "/_",
# so this file is not pulled into the flake's module tree.
{
  # The host half of tern-jj.
  #
  # It owns the jj CLI, the status refresh and the workspace create, open
  # and remove work. The host half runs in the session daemon, on the
  # plugin's own worker thread, with a 2 s budget per call. Every jj
  # process, every file read and every pane-state read belongs here,
  # because each of them costs the window's UI thread its 50 ms budget
  # when it runs there.
  #
  # The window half asks for work and reads the published status map. It
  # never spawns a process, never reads a file and never calls the daemon.
  #
  # `settings` is the settings Luau the window half also uses; `channel` is
  # the shared transport.
  jjHost =
    {
      settings,
      channel,
    }:
    # luau
    ''
            ${settings}

            ${channel}

            local STATUS_TEMPLATE = table.concat({
              'if(conflict, "1", "") ++ "\\x1f" ++ ',
              'if(empty, "1", "") ++ "\\x1f" ++ ',
              'change_id.shortest(12) ++ "\\x1f" ++ ',
              'self.diff().files().len() ++ "\\x1f" ++ ',
              'local_bookmarks.map(|b| b.name()).join(" ") ++ "\\n"',
            })

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

            -- The host half has no window to toast into: a host timer callback
            -- gets no cx, and only an event handler does. So the host reports
            -- through its answers and its log, and the window half toasts.
            local function note(level, text, sub)
              tern.log.warn(text, sub)
            end

            -- The channel is declared before the work that uses it: the
            -- functions below call `channel.publish` and `channel.answer`, and
            -- a local that is declared later is nil at that point.
            --
            -- `handle` is declared here and assigned at the end, for the same
            -- reason: the channel's poll calls it.
            local handle
            local channel = channel_host(function(request, name)
              return handle(request, name)
            end)

            local function detail_of(result)
              local detail = trim(result.stderr)
              if detail == "" then
                detail = trim(result.stdout)
              end
              if result.timed_out then
                detail = detail == "" and "timed out and was killed" or (detail .. " (timed out; killed)")
              end
              return detail
            end

            -- One jj process. The callback runs on the host worker, so a slow
            -- jj costs the host its 2 s budget and not the window's 50 ms one.
            local function jj(args, opts, on_done)
              if type(opts) == "function" then
                on_done, opts = opts, nil
              end
              local options = opts or {}
              if options.timeout_ms == nil then
                options.timeout_ms = 120000
              end
              local ok, err = pcall(tern.process.run, args, options, function(result, cb_cx)
                if on_done ~= nil then
                  on_done(result, cb_cx)
                end
              end)
              if not ok then
                note("error", "could not run jj", tostring(err))
              end
            end

            -- The main workspace of a workspace root: the directory that holds
            -- the .jj directory, found through the repo pointer.
            --
            -- The pointer is a file only in a workspace that is not the
            -- repository's own root: there, .jj/repo is a file that names the
            -- store. In the repository's own root, .jj/repo is a directory
            -- that holds the store, and the root is the main root itself.
            local function main_root_of(root)
              local pointer = root .. "/.jj/repo"
              if not tern.fs.exists(pointer) then
                return nil
              end

              -- A directory holds the store; a file names it. Listing the
              -- path tells the two apart, because a file has no entries to
              -- list. A file that lists as empty is still a file, so the
              -- check asks for entries and not for a table.
              local listed_ok, listed = pcall(tern.fs.list, pointer)
              if listed_ok and type(listed) == "table" and #listed > 0 then
                -- The root's own .jj/repo is a directory: the root is the
                -- main root.
                return root
              end

              local ok, text = pcall(tern.fs.read, pointer)
              if ok and type(text) == "string" then
                local store = trim(text)
                if store == "" then
                  return root
                end
                local joined = string.sub(store, 1, 1) == "/" and store or (root .. "/.jj/" .. store)

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

            -- A tab is named repo/workspace.
            local function tab_name(main_root, name)
              return repo_name(main_root) .. "/" .. name
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

            -- The status of one directory.
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
              -- The segments the status bar shows, built once here: the status
              -- hook fires per pane per redraw, and allocating a fresh table
              -- every call tripped its 4 ms budget. with_distance rebuilds it
              -- when it prepends a distance part.
              local segments = { { text = (bookmarks ~= nil and bookmarks ~= "") and bookmarks or ("@" .. change), icon = "branch" } }
              for _, part in ipairs(parts) do
                table.insert(segments, part)
              end
              return { change = (bookmarks ~= nil and bookmarks ~= "") and bookmarks or ("@" .. change), parts = parts, segments = segments, cwd = cwd }
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

            -- The distance to the remote, per bookmark: "+N" ahead, "-N" behind.
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
                    -- A distance part joined the front: rebuild the cached
                    -- segments so the status hook shows it.
                    entry.segments = { { text = entry.change, icon = "branch" } }
                    for _, part in ipairs(entry.parts) do
                      table.insert(entry.segments, part)
                    end
                  end
                  with_distance(entry, names, index + 1, done)
                end)
              end)
            end

            -- The status map: directory -> the segments the window shows.
            local status_map = {}

            -- The directories the host is reading, so a second refresh does not
            -- start a second jj.
            local reading = {}

            -- The status as it was published last, so an unchanged status is
            -- not published again.
            local last_published: string? = nil

            local function publish_status()
      	-- The status is published only when it changed. A publish is a
      	-- file write, and the host's 2 s budget covers the whole tick,
      	-- so a tick that writes every time leaves the host with no
      	-- headroom for the requests it answers.
      	local encoded = tern.json.encode(status_map)
      	if encoded == last_published then
      		return
      	end
      	last_published = encoded
      	channel.publish("status", status_map)
            end

            -- Read the status of one directory and add it to the map.
            local function refresh_one(cwd, done)
              if reading[cwd] then
                done()
                return
              end
              reading[cwd] = true
              read_status(cwd, function(entry)
                reading[cwd] = nil
                if entry == nil then
                  done()
                  return
                end
                local names = {}
                for name in string.gmatch(entry.change, "%S+") do
                  table.insert(names, name)
                end
                with_distance(entry, names, 1, function()
                  status_map[cwd] = { change = entry.change, parts = entry.parts, segments = entry.segments }
                  publish_status()
                  done()
                end)
              end)
            end

            -- The directories the panes are in. The host reads them itself, so
            -- the window never has to ask for a refresh.
            local function pane_cwds()
              local out = {}
              local seen = {}
              local ok, panes = pcall(tern.pane.list)
              if not ok then
                return out
              end
              for _, pane in ipairs(panes) do
                local cwd = pane.cwd
                if cwd ~= nil and cwd ~= "" and not seen[cwd] then
                  seen[cwd] = true
                  table.insert(out, cwd)
                end
              end
              return out
            end

            -- Refresh every directory that has no status yet, one after the
            -- other, so a burst of panes does not start a burst of jj.
            local refreshing = false
            local function refresh_all(force, done)
              if refreshing then
                if done ~= nil then
                  done()
                end
                return
              end
              refreshing = true
              local cwds = pane_cwds()
              local index = 0
              local function step()
                index = index + 1
                local cwd = cwds[index]
                if cwd == nil then
                  refreshing = false
                  if done ~= nil then
                    done()
                  end
                  return
                end
                if force or status_map[cwd] == nil then
                  refresh_one(cwd, step)
                else
                  step()
                end
              end
              step()
            end

            -- The workspaces of a main root: the name, the change and the
            -- checkout directory.
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

            -- The workspace root of a directory.
            local function root_of(cwd, cb)
              jj({ "jj", "--no-pager", "--ignore-working-copy", "-R", cwd, "workspace", "root" }, function(result)
                local root = trim(result.stdout)
                if result.status ~= 0 or root == "" then
                  cb(nil)
                  return
                end
                cb(root)
              end)
            end

            -- The main root of every workspace this host made, so a rollback
            -- finds it without the window half having to know it.
            local made = {}

            -- Undo a workspace the window half could not open a tab for.
            local function rollback(cx, main_root, name, root, answer)
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
                    note("error", "forgetting " .. name .. " failed", detail_of(result))
                    answer({ rolled_back = false })
                    return
                  end
                  if tern.fs.exists(root) then
                    tern.fs.remove(root)
                  end
                  answer({ rolled_back = true })
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

            -- Create a workspace and answer with the directory it lives in.
            local function create(cwd, name, answer)
              if not valid_name(name) then
                answer({ error = "workspace name must match [A-Za-z0-9._/-]", detail = tostring(name) })
                return
              end

              root_of(cwd, function(root)
                if root == nil then
                  answer({ error = "not a jj workspace", detail = cwd })
                  return
                end
                local main_root = main_root_of(root)
                if main_root == nil then
                  answer({ error = "could not find the main jj workspace", detail = root })
                  return
                end

                list_workspaces(main_root, function(ok, items)
                  if not ok then
                    answer({ error = "jj workspace list failed", detail = main_root })
                    return
                  end
                  for _, item in ipairs(items) do
                    if item.name == name then
                      answer({ error = "jj workspace already exists", detail = name })
                      return
                    end
                  end

                  local checkout = workspaceRoot .. "/" .. repo_name(main_root) .. "/" .. slug(name)
                  if tern.fs.exists(checkout) then
                    answer({ error = "checkout path already exists", detail = checkout })
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
                    local fetch_note = nil
                    if fetch_result.status ~= 0 then
                      fetch_note = "fetch failed, using the local change: " .. trim(fetch_result.stderr)
                      note("info", fetch_note)
                    end

                    jj({ "mkdir", "-p", "--", checkout }, function(mkdir_result)
                      if mkdir_result.status ~= 0 then
                        answer({ error = "could not create " .. checkout, detail = trim(mkdir_result.stderr) })
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
                          answer({ error = "jj workspace add " .. name .. " failed", detail = detail_of(add_result) })
                          return
                        end

                        made[name] = { main_root = main_root, root = checkout }

                        if not createBookmark then
                          answer({ root = checkout, name = name, created = true, label = tab_name(main_root, name), note = fetch_note })
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
                            note("error", "jj bookmark create " .. name .. " failed", detail_of(bookmark_result))
                          end
                          answer({ root = checkout, name = name, created = true, label = tab_name(main_root, name), note = fetch_note })
                        end)
                      end)
                    end)
                  end)
                end)
              end)
            end

            -- The workspaces to offer in the picker.
            local function open(cwd, answer)
              root_of(cwd, function(root)
                if root == nil then
                  answer({ error = "not a jj workspace", detail = cwd })
                  return
                end
                local main_root = main_root_of(root)
                if main_root == nil then
                  answer({ error = "could not find the main jj workspace", detail = root })
                  return
                end

                list_workspaces(main_root, function(ok, items)
                  if not ok then
                    answer({ error = "jj workspace list failed", detail = main_root })
                    return
                  end
                  if #items == 0 then
                    answer({ error = "no jj workspaces", detail = main_root })
                    return
                  end
                  -- The label is the tab name, and the tab name needs the main
                  -- root, which needs a file read. The host does that read.
                  for _, item in ipairs(items) do
                    item.label = tab_name(main_root, item.name)
                  end
                  answer({ items = items, main_root = main_root, current = root })
                end)
              end)
            end

            -- Forget a workspace and delete its checkout.
            local function remove(cwd, answer)
              root_of(cwd, function(root)
                if root == nil then
                  answer({ error = "not a jj workspace", detail = cwd })
                  return
                end
                local main_root = main_root_of(root)
                if main_root == nil then
                  answer({ error = "could not find the main jj workspace", detail = root })
                  return
                end
                if main_root == root then
                  answer({ error = "refusing to remove the main jj workspace", detail = root })
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
                    answer({ error = "could not identify the current jj workspace", detail = root })
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
                      answer({ error = "jj status failed", detail = detail_of(status_result) })
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
                        answer({ error = "jj workspace forget " .. name .. " failed", detail = detail_of(forget_result) })
                        return
                      end

                      -- The window half closes the tab that held the workspace.
                      answer({ removed = true, root = root, name = name })

                      if not tern.fs.exists(root) then
                        note("success", "forgot " .. name)
                        return
                      end

                      jj({ "rm", "-rf", "--", root }, { timeout_ms = 300000 }, function(rm_result)
                        if rm_result.status ~= 0 then
                          note("error", "forgot " .. name .. ", but could not delete its checkout", root)
                        else
                          note("success", "removed " .. name, root)
                        end
                      end)
                    end)
                  end)
                end)
              end)
            end

            -- The requests the window half makes.
            --
            -- A request that needs a jj process answers later, through
            -- `channel.answer`, so the answer is not lost when the work takes
            -- longer than one call.
            --
            -- It is assigned, not declared as a function, because the channel
            -- above already holds a reference to it.
            handle = function(request, name)
              if type(request) ~= "table" then
                return nil
              end
              local action = request.action

              if action == "refresh" then
                refresh_all(request.force == true, function()
                  publish_status()
                end)
                return { ok = true }
              end

              if action == "create" then
                create(request.cwd, request.name, function(payload)
                  channel.answer(name, payload)
                end)
                return nil
              end

              if action == "open" then
                open(request.cwd, function(payload)
                  channel.answer(name, payload)
                end)
                return nil
              end

              if action == "remove" then
                remove(request.cwd, function(payload)
                  channel.answer(name, payload)
                end)
                return nil
              end

              if action == "rollback" then
                local entry = made[request.name]
                if entry == nil then
                  return { error = "no workspace to roll back" }
                end
                rollback(nil, entry.main_root, request.name, entry.root, function(payload)
                  channel.answer(name, payload)
                end)
                return nil
              end

              return { error = "unknown request" }
            end

            -- A slow refresh: the status of a directory does not change by the
            -- millisecond, and a jj process per pane would load the daemon.
            local function tick()
              refresh_all(false, nil)
              tern.timer(3000, tick)
            end
            tern.timer(1000, tick)
    '';
}
