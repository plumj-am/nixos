{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-copse-status: the copse queue in the status line.
      #
      # A chip counts the jobs copse runs (and the frozen ones among them) and
      # the jobs it queues; nothing shows while no daemon answers. A chip
      # click opens the copse TUI as an overlay.
      #
      # `copse list` STARTS the daemon when no socket answers, so the poll
      # checks the socket first and reports nothing while the daemon is down.
      packages.tern-copse-status-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-copse-status-plugin.toml" {
            schema = 1;
            id = "copse-status";
            name = "Copse Status";
            version = "0.1.0";
            description = "Status-line summary of the copse queue; click for the copse TUI.";
            icon = "terminal";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-copse-status-init.luau" # luau
              ''
                --!nonstrict

                local ID = "copse-status"
                local OPEN = "plugin." .. ID .. ".open"

                -- One poll is one socket round trip (about 12 ms), so five
                -- seconds stays cheap; the timer hook has 50 ms.
                local TICK_MS = 5000
                local TIMEOUT_MS = 5000

                local counts = { running = 0, queued = 0, frozen = 0 }
                local shown = "0/0/0"

                -- The daemon's socket, as copse resolves it without a config
                -- override (config.rs `socket_path`).
                local function socket_path()
                	local runtime = tern.getenv("XDG_RUNTIME_DIR")
                	if runtime ~= nil and runtime ~= "" then
                		return runtime .. "/copse/copse.sock"
                	end
                	local state = tern.getenv("XDG_STATE_HOME")
                	if state == nil or state == "" then
                		local home = tern.getenv("HOME")
                		if home == nil or home == "" then
                			return nil
                		end
                		state = home .. "/.local/state"
                	end
                	return state .. "/copse/copse.sock"
                end

                -- A change through any window drops the formatter's cache.
                local function set_counts(fresh)
                	local encoded = ("%d/%d/%d"):format(fresh.running, fresh.queued, fresh.frozen)
                	if encoded == shown then
                		return
                	end
                	counts = fresh
                	shown = encoded
                	tern.chrome.refresh()
                end

                -- `copse list --json` answers with one JobView per retained
                -- job: all states, newest first, up to the retention limit.
                local function summarise(entries)
                	local fresh = { running = 0, queued = 0, frozen = 0 }
                	for _, entry in ipairs(entries) do
                		local job = if type(entry) == "table" then entry.job else nil
                		if type(job) == "table" then
                			if job.state == "running" then
                				fresh.running += 1
                				if job.frozen == true then
                					fresh.frozen += 1
                				end
                			elseif job.state == "queued" then
                				fresh.queued += 1
                			end
                		end
                	end
                	return fresh
                end

                local polling = false

                local function refresh()
                	local path = socket_path()
                	if path == nil or not tern.fs.exists(path) then
                		set_counts({ running = 0, queued = 0, frozen = 0 })
                		return
                	end
                	if polling then
                		return
                	end
                	polling = true
                	local started, spawn_error = pcall(function()
                		tern.process.run({ "copse", "list", "--json" }, { timeout_ms = TIMEOUT_MS }, function(result)
                			polling = false
                			if result.status ~= 0 then
                				tern.log.warn("copse status: copse list failed with status " .. tostring(result.status))
                				return
                			end
                			local decoded_ok, decoded = pcall(tern.json.decode, result.stdout)
                			if not decoded_ok or type(decoded) ~= "table" then
                				tern.log.warn("copse status: could not decode the copse list output")
                				return
                			end
                			set_counts(summarise(decoded))
                		end)
                	end)
                	if not started then
                		polling = false
                		tern.log.warn("copse status: could not start copse: " .. tostring(spawn_error))
                	end
                end

                -- The TUI takes the overlay over the focused pane and gives the
                -- focus back when it exits.
                tern.command({
                	id = "open",
                	title = "Copse",
                	icon = "terminal",
                	group = "copse-status",
                	run = function(cx)
                		local origin = cx.session:focused()
                		if origin == nil then
                			cx:toast("error", "no focused pane to overlay copse")
                			return
                		end
                		local pane = cx.layout:split(origin, "right", { command = "copse" }, { focus = false })
                		if pane == nil then
                			cx:toast("error", "could not open copse")
                			return
                		end
                		local floated, float_error = cx.layout:float(pane, origin)
                		if not floated then
                			cx.layout:close(pane)
                			cx:toast("error", "could not overlay copse", float_error)
                			return
                		end
                		cx.layout:focus(pane)
                	end,
                })

                tern.chrome.status(function(_pane)
                	local segments = {}
                	if counts.running > 0 then
                		table.insert(segments, {
                			text = counts.running .. " running",
                			icon = "run",
                			tone = "accent",
                			command = OPEN,
                		})
                	end
                	if counts.frozen > 0 then
                		table.insert(segments, {
                			text = counts.frozen .. " frozen",
                			tone = "warn",
                			command = OPEN,
                		})
                	end
                	if counts.queued > 0 then
                		table.insert(segments, {
                			text = counts.queued .. " queued",
                			tone = "muted",
                			command = OPEN,
                		})
                	end
                	if #segments == 0 then
                		return nil
                	end
                	return segments
                end)

                -- Rearm first: a callback cut off at the budget must not end
                -- the chain.
                local function loop()
                	tern.timer(TICK_MS, loop)
                	refresh()
                end
                tern.timer(100, loop)
              '';
        in
        pkgs.runCommand "tern-copse-status-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
