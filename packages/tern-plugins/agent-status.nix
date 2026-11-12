{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-agent-status: a status-line summary of every agent, and a picker
      # that opens from any summary segment or alt+shift+a.
      #
      # The summary counts what needs attention: waiting for input, working,
      # failed turns and unread done turns. Idle agents stay out of the status
      # line and appear in the picker under Idle.
      #
      # The window has no clock beyond os.time(), so each pane's state and
      # since time live in tern.kv. Every window and a reload then agree on
      # ages and unread turns.
      packages.tern-agent-status-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-agent-status-plugin.toml" {
            schema = 1;
            id = "agent-status";
            name = "Agent Status";
            version = "0.1.0";
            description = "Status-line summary of every agent; click or alt+shift+a for the list.";
            icon = "activity";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-agent-status-init.luau" # luau
              ''
                --!nonstrict

                local ID = "agent-status"
                local OPEN = "plugin." .. ID .. ".open"

                -- Tern's status tones with built-in styles; other names are
                -- only CSS attributes and render uncoloured.
                local TONE = { wait = "warn", work = "accent", fail = "error", done = "ok" }

                -- Waiting first, then the live states, then the ended ones.
                local RANK = { wait = 1, work = 2, fail = 3, done = 4, idle = 5, exited = 6 }

                local GROUP = {
                	wait = "Needs you",
                	work = "Working",
                	fail = "Failed",
                	done = "Done",
                	idle = "Idle",
                	exited = "Idle",
                }

                local PICK_ICON = {
                	wait = "message",
                	work = "run",
                	fail = "x",
                	done = "check",
                	idle = "pause",
                	exited = "power",
                }

                -- A slow safety tick heals a missed event; state changes arrive
                -- by event, so this is not the main driver.
                local TICK_MS = 30000

                -- Per-pane memory, keyed by pane id as a string because kv keys
                -- are strings. Mirrored to tern.kv so windows and reloads agree.
                local memory = {}
                local stored_memory = ""

                local function text(value)
                	if type(value) == "string" then
                		return value
                		end
                	return nil
                end

                local function number(value)
                	if type(value) == "number" then
                		return value
                		end
                	return nil
                end

                local function read_kv(key)
                	local ok, value = pcall(tern.kv.get, key)
                	if not ok then
                		tern.log.warn("agent status: could not read " .. key)
                		return nil
                	end
                	return value
                end

                local function write_kv(key, value)
                	local ok = pcall(tern.kv.set, key, value)
                	if not ok then
                		tern.log.warn("agent status: could not write " .. key)
                	end
                end

                -- Rebuilds the memory when another window wrote a different
                -- copy. Encoding first keeps the usual tick free of writes.
                local function load_memory()
                	local value = read_kv("memory")
                	if type(value) ~= "table" then
                		return
                	end
                	local encoded = tern.json.encode(value)
                	if encoded == stored_memory then
                		return
                	end
                	memory = {}
                	for key, entry in pairs(value) do
                		if
                			type(entry) == "table"
                			and type(entry.phase) == "string"
                			and type(entry.at) == "number"
                		then
                			memory[tostring(key)] = {
                				phase = entry.phase,
                				at = entry.at,
                				ending = if type(entry.ending) == "string" then entry.ending else nil,
                				pending = if type(entry.pending) == "string" then entry.pending else nil,
                				read = entry.read == true,
                			}
                		end
                	end
                	stored_memory = encoded
                end

                local function save_memory()
                	local encoded = tern.json.encode(memory)
                	if encoded == stored_memory then
                		return
                	end
                	write_kv("memory", memory)
                	stored_memory = encoded
                end

                -- A program that has exited must not read as green, even while
                -- the agent list still calls it idle.
                local function state_of(agent)
                	if agent.alive == false then
                		return "exited"
                	end
                	local state = text(agent.state)
                	if state == nil then
                		return "idle"
                	elseif state == "exited" then
                		return "exited"
                	end
                	return state
                end

                -- Moves one remembered pane to its next phase, keeping the
                -- turn that just ended and whether the person has seen it.
                local function advance(entry, phase, pane, focused, now)
                	local prior = entry.phase
                	if phase == "working" then
                		entry.ending = nil
                		entry.pending = nil
                	elseif phase == "idle" and (prior == "working" or prior == "waiting_input") then
                		entry.ending = entry.pending or "done"
                		entry.pending = nil
                		entry.read = pane == focused
                	end
                	entry.phase = phase
                	entry.at = now
                end

                local function remember_agents(agents, focused, now)
                	local seen = {}
                	for _, agent in ipairs(agents) do
                		local id = tostring(agent.pane)
                		seen[id] = true
                		local phase = state_of(agent)
                		local entry = memory[id]
                		if entry == nil then
                			-- First sight has no turn to report.
                			memory[id] = { phase = phase, at = now, read = true }
                		elseif entry.phase ~= phase then
                			advance(entry, phase, agent.pane, focused, now)
                		end
                	end
                	for id in pairs(memory) do
                		if not seen[id] then
                			memory[id] = nil
                		end
                	end
                end

                -- agent_finished arrives just before the idle agent_state. Hold
                -- its result until that transition, or record it now when the
                -- pane is already idle.
                local function record_ending(pane, result, focused, now)
                	if result ~= "done" and result ~= "failed" then
                		return
                	end
                	local id = tostring(pane)
                	local entry = memory[id]
                	if entry == nil then
                		memory[id] = { phase = "idle", at = now, ending = result, read = pane == focused }
                		return
                	end
                	if entry.phase ~= "idle" then
                		entry.pending = result
                		return
                	end
                	if entry.ending ~= nil or result == "failed" then
                		entry.ending = result
                		entry.read = entry.read and pane == focused
                	end
                end

                local function mark_read(pane)
                	local entry = memory[tostring(pane)]
                	if entry == nil or entry.read then
                		return false
                	end
                	entry.read = true
                	return true
                end

                local PHASE_KIND = { waiting_input = "wait", working = "work", exited = "exited" }

                -- waiting and working come from the live phase; an idle pane
                -- reads as done or failed only while its ending is unread.
                local function classify(phase, entry)
                	local kind = PHASE_KIND[phase]
                	if kind ~= nil then
                		return kind
                	end
                	if entry ~= nil and entry.ending ~= nil and not entry.read then
                		return entry.ending == "failed" and "fail" or "done"
                	end
                	return "idle"
                end

                -- UTF-8 aware cut, so a name or message never splits a glyph.
                local function clip(value, limit)
                	local length = utf8.len(value)
                	if length == nil or length <= limit then
                		return value
                	end
                	local stop = utf8.offset(value, limit)
                	if stop == nil then
                		return value
                	end
                	return string.sub(value, 1, stop - 1) .. "…"
                end

                local function folder_name(path)
                	local trimmed = string.gsub(path, "/+$", "")
                	local slash = string.find(trimmed, "/[^/]*$")
                	if slash == nil then
                		return trimmed
                	end
                	return string.sub(trimmed, slash + 1)
                end

                local function first_line(value, limit)
                	if value == nil then
                		return nil
                	end
                	for line in string.gmatch(value, "[^\n]+") do
                		local trimmed = string.match(line, "^%s*(.-)%s*$") or ""
                		if trimmed ~= "" then
                			return clip(trimmed, limit)
                		end
                	end
                	return nil
                end

                local function span_text(seconds)
                	local whole = math.max(0, math.floor(seconds))
                	if whole < 60 then
                		return "<1m"
                	elseif whole < 3600 then
                		return (whole // 60) .. "m"
                	elseif whole < 86400 then
                		return (whole // 3600) .. "h"
                	end
                	return (whole // 86400) .. "d"
                end

                local function age_label(kind, seconds)
                	local span = span_text(seconds)
                	if kind == "wait" or kind == "work" then
                		return span
                	elseif span == "<1m" then
                		return "just now"
                	end
                	return span .. " ago"
                end

                local function urgency(a, b)
                	local ranked = RANK[a.kind] - RANK[b.kind]
                	if ranked ~= 0 then
                		return ranked < 0
                	end
                	-- Waiting and working: the longest first. The rest: the most
                	-- recent first.
                	local newest_first = a.kind ~= "wait" and a.kind ~= "work"
                	if a.since ~= b.since then
                		if newest_first then
                			return a.since > b.since
                		end
                		return a.since < b.since
                	end
                	if type(a.pane) == "number" and type(b.pane) == "number" then
                		return a.pane < b.pane
                	end
                	return tostring(a.pane) < tostring(b.pane)
                end

                local function read_snapshot(cx)
                	local agents = cx.agents:list()
                	local sessions = cx.session:sessions()
                	local tabs = cx.session:tabs()
                	local focused = cx.session:focused()
                	local now = os.time()
                	load_memory()
                	remember_agents(agents, focused, now)
                	save_memory()

                	local session_names = {}
                	for _, session in ipairs(sessions) do
                		local name = text(session.name)
                		if name ~= nil and name ~= "" then
                			session_names[session.id] = name
                		end
                	end
                	local positions = {}
                	for _, tab in ipairs(tabs) do
                		positions[tab.id] = number(tab.position)
                	end

                	local rows = {}
                	local counts = { wait = 0, work = 0, fail = 0, done = 0, idle = 0 }
                	for _, agent in ipairs(agents) do
                		local phase = state_of(agent)
                		local entry = memory[tostring(agent.pane)]
                		local kind = classify(phase, entry)
                		local bucket = if kind == "exited" then "idle" else kind
                		counts[bucket] += 1

                		local cwd = text(agent.cwd) or ""
                		local name = if cwd ~= "" then folder_name(cwd) else (text(agent.title) or ("pane " .. agent.pane))
                		local session_name = session_names[number(agent.session)]
                		local place = if agent.parked == true then "parked" else tostring(positions[number(agent.tab)] or "")
                		if place == "" then
                			place = nil
                		end
                		local location = ""
                		if session_name ~= nil and place ~= nil then
                			location = session_name .. " › " .. place
                		elseif session_name ~= nil then
                			location = session_name
                		elseif place ~= nil then
                			location = place
                		end

                		local since = if entry ~= nil then entry.at else now
                		local message = first_line(text(agent.last_message), 80)
                		local delivery_error = first_line(text(agent.delivery_error), 80)
                		local is_error = false
                		if delivery_error ~= nil then
                			message = delivery_error
                			is_error = true
                		elseif message == nil and kind == "wait" then
                			message = "Waiting for your input"
                		end

                		table.insert(rows, {
                			pane = agent.pane,
                			kind = kind,
                			name = name,
                			location = location,
                			since = since,
                			age = age_label(kind, now - since),
                			message = message,
                			error = is_error,
                			focused = agent.pane == focused,
                			parked = agent.parked == true,
                			session = number(agent.session),
                		})
                	end

                	table.sort(rows, urgency)
                	return { rows = rows, counts = counts, total = #rows }
                end

                -- The picker labels must distinguish two agents in the same
                -- folder. The location does that first; the pane id last.
                local function pick_items(rows)
                	local name_counts = {}
                	for _, row in ipairs(rows) do
                		name_counts[row.name] = (name_counts[row.name] or 0) + 1
                	end
                	local labels = {}
                	local label_counts = {}
                	for index, row in ipairs(rows) do
                		local label = row.name
                		if name_counts[row.name] > 1 then
                			label = row.name .. " · " .. (if row.location ~= "" then row.location else "pane " .. row.pane)
                		end
                		labels[index] = label
                		label_counts[label] = (label_counts[label] or 0) + 1
                	end

                	local items = {}
                	for index, row in ipairs(rows) do
                		local label = labels[index]
                		if label_counts[label] > 1 then
                			label = label .. " · pane " .. row.pane
                		end
                		local parts = {}
                		if row.kind == "wait" then
                			if row.message ~= nil then
                				table.insert(parts, row.message)
                			end
                			if row.location ~= "" then
                				table.insert(parts, row.location)
                			end
                			table.insert(parts, row.age)
                		else
                			if row.location ~= "" then
                				table.insert(parts, row.location)
                			end
                			table.insert(parts, row.age)
                			if row.message ~= nil then
                				table.insert(parts, row.message)
                			end
                		end
                		table.insert(items, {
                			label = label,
                			detail = table.concat(parts, " · "),
                			group = GROUP[row.kind],
                			icon = PICK_ICON[row.kind],
                			current = row.focused,
                			pane = row.pane,
                			session = row.session,
                			parked = row.parked,
                		})
                	end
                	return items
                end

                local counts = { wait = 0, work = 0, fail = 0, done = 0, idle = 0 }
                local shown_counts = "0/0/0/0/0"

                -- The native picker covers the window and draws its card near
                -- the top. While our picker is open, this sheet puts the card
                -- above the widget bar. The sheet is global for that moment,
                -- but the picker is modal, so no other picker can be open.
                local PICKER_CSS = [[
#pick .tn-pk {
	position: absolute !important;
	top: auto !important;
	bottom: 44px !important;
	left: auto !important;
	right: 24px !important;
	transform: none !important;
	max-width: calc(100vw - 32px);
	margin: 0 !important;
}
]]

                -- The formatter reads only these counts; a change drops its
                -- cache and runs it again.
                local function set_counts(fresh)
                	local encoded = ("%d/%d/%d/%d/%d"):format(fresh.wait, fresh.work, fresh.fail, fresh.done, fresh.idle)
                	if encoded == shown_counts then
                		return
                	end
                	counts = fresh
                	shown_counts = encoded
                	tern.chrome.refresh()
                end

                -- A failed read keeps the last good summary rather than
                -- clearing the status line on a transient error.
                local function refresh(cx)
                	local ok, model = pcall(read_snapshot, cx)
                	if not ok then
                		tern.log.warn("agent status: " .. tostring(model))
                		return nil
                	end
                	set_counts(model.counts)
                	return model
                end

                tern.command({
                	id = "open",
                	title = "Agent Status",
                	icon = "activity",
                	keys = { "alt+shift+a" },
                	run = function(cx)
                		local model = refresh(cx)
                		if model == nil then
                			cx:toast("error", "Agent Status could not read the agents", "See Tern's log.")
                			return
                		end
                		if model.total == 0 then
                			cx:toast("info", "No agents running")
                			return
                		end
                		tern.css("picker", PICKER_CSS)
                		cx:pick({
                			items = pick_items(model.rows),
                			placeholder = "Agents",
                			icon = "activity",
                			action = "jump",
                		}):next(function(item, _err, fresh)
                			tern.css("picker", "")
                			if item == nil or fresh == nil or type(item.pane) ~= "number" then
                				return
                			end
                			if item.parked == true then
                				if type(item.session) == "number" then
                					fresh.sessions:switch(item.session)
                				end
                				fresh.layout:unpark(item.pane)
                			end
                			fresh.layout:focus(item.pane)
                			load_memory()
                			if mark_read(item.pane) then
                				save_memory()
                			end
                			refresh(fresh)
                		end)
                	end,
                })

                tern.chrome.status(function(_pane)
                	local segments = {}
                	if counts.wait > 0 then
                		table.insert(segments, {
                			text = counts.wait .. " need you",
                			icon = "bell",
                			tone = TONE.wait,
                			command = OPEN,
                		})
                	end
                	if counts.work > 0 then
                		table.insert(segments, {
                			text = counts.work .. " working",
                			icon = "run",
                			tone = TONE.work,
                			command = OPEN,
                		})
                	end
                	if counts.fail > 0 then
                		table.insert(segments, {
                			text = counts.fail .. " failed",
                			icon = "x",
                			tone = TONE.fail,
                			command = OPEN,
                		})
                	end
                	if counts.done > 0 then
                		table.insert(segments, {
                			text = counts.done .. " done",
                			icon = "check",
                			tone = TONE.done,
                			command = OPEN,
                		})
                	end
                	if #segments == 0 then
                		return nil
                	end
                	return segments
                end)

                -- Rearm first: a handler cut off at the budget must not end
                -- the chain.
                local function loop(cx)
                	tern.timer(TICK_MS, loop)
                	if cx ~= nil then
                		refresh(cx)
                	end
                end
                tern.timer(100, loop)

                tern.on("focus", function(event, cx)
                	load_memory()
                	if mark_read(event.pane) then
                		save_memory()
                	end
                	refresh(cx)
                end)

                tern.on("agent_finished", function(event, cx)
                	load_memory()
                	record_ending(event.pane, event.result, cx.session:focused(), os.time())
                	save_memory()
                	refresh(cx)
                end)

                tern.on("agent_state", function(_event, cx)
                	refresh(cx)
                end)

                for _, event in { "pane_created", "pane_closed" } do
                	tern.on(event, function(_event, cx)
                		refresh(cx)
                	end)
                end
              '';
        in
        pkgs.runCommand "tern-agent-status-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
