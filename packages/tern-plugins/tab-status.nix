{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-tab-status: one letter per tab per task kind, coloured by state.
      #
      #   S  shell task    waiting  orange, pulsing
      #   A  agent task    working  purple, pulsing
      #                    failed   red, steady
      #                    finished green, steady
      #
      # A tab with several panes of a kind draws one letter, in the most
      # urgent state. The letters ride the pane deck in the rail and the face
      # container in the horizontal bar; Tern's dots and face icons are
      # hidden. The sheet comes from tern.css, not the manifest, so its
      # `::after` rules reinstall on every rebuild call.
      #
      # Hook budgets are wall clock and a tripped hook stays disabled until
      # the next reload, so the cheap reads (panes, tabs) run every tick and
      # the agent list every ten seconds. The timer is the first driver and
      # the window events the second: an event that finds the timer quiet
      # does the work itself.
      packages.tern-tab-status-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-tab-status-plugin.toml" {
            schema = 1;
            id = "tab-status";
            name = "tern-tab-status";
            version = "0.1.0";
            description = "Tab task state: S for a shell, A for an agent, coloured by state.";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-tab-status-init.luau" # luau
              ''
                --!nonstrict

                local CSS = [==[
                /* Rail: the deck at the row's right end holds the letters. */
                .tn-vt .nav-row > .tn-dk {
                	order: 999;
                	margin-left: auto;
                	display: flex;
                	align-items: center;
                	justify-content: flex-end;
                	gap: 2px;
                	width: auto;
                	min-width: var(--dk);
                }

                /* Horizontal tabs: the face container takes the tab's right end. */
                #tabbar .tt > .fc {
                	order: 999;
                	flex: none;
                	margin-left: auto;
                	display: flex;
                	align-items: center;
                	justify-content: flex-end;
                	gap: 3px;
                }

                #tabbar .tt > .fc > .tn-face {
                	display: none;
                }

                /* The letters. */
                .tn-vt .nav-row > .tn-dk::before,
                .tn-vt .nav-row > .tn-dk::after,
                #tabbar .tt > .fc::before,
                #tabbar .tt > .fc::after {
                	font: 700 10px/1 var(--mono);
                }

                /* The tiles keep their box and lose their icon, fill,
                   shimmer and state dot. */
                .tn-vt .nav-row .tn-dk-c {
                	background: transparent;
                	box-shadow: none;
                	filter: none;
                	color: transparent;
                	font-size: 0;
                }

                .tn-vt .nav-row .tn-dk-c::before,
                .tn-vt .nav-row .tn-dk-c > svg.ico,
                .tn-vt .nav-row .tn-dk-c .tn-dk-g {
                	display: none;
                }

                .tn-vt .nav-row .tn-dk-c[data-st]::after {
                	display: none;
                }

                /* Collapse every tile onto the deck box; !important beats
                   Tern's per-index rules. */
                .tn-vt .nav-row .tn-dk-c {
                	left: 0 !important;
                	top: 0 !important;
                	width: 100%;
                	height: 100%;
                	transform: none !important;
                }

                /* No key-hint labels: the bindings still work. */
                .tn-vt .nav-row .kbd.tn-num,
                .tn-vt .nav-row .meta,
                #tabbar .tt .kbd.tn-num,
                #tabbar .tt .mk.keys {
                	display: none;
                }

                /* No close cross: Tern parks it at the row's end, where the
                   deck now is. Tabs close with the keymap. */
                .tn-vt .nav-row > .tn-tx,
                #tabbar .tt > .tn-tx {
                	display: none;
                }

                /* One pulse for the live states; finished holds still.
                   !important beats the gate rules, which carry an id. */
                @keyframes tab-status-pulse {
                	0%,
                	100% {
                		opacity: 1;
                	}
                	50% {
                		opacity: 0.35;
                	}
                }

                @media (prefers-reduced-motion: reduce) {
                	.tn-vt .nav-row > .tn-dk::before,
                	.tn-vt .nav-row > .tn-dk::after,
                	#tabbar .tt > .fc::before,
                	#tabbar .tt > .fc::after {
                		animation: none !important;
                	}
                }
                ]==]

                -- A state's colour; no theme variable carries purple, so it
                -- is literal.
                local COLOUR = {
                	waiting = "var(--warn)",
                	working = "#b48cf2",
                	failed = "var(--bad)",
                	done = "var(--ok)",
                }

                -- Lower rank wins when a tab holds several tasks of a kind.
                local RANK = {
                	waiting = 1,
                	working = 2,
                	failed = 3,
                	done = 4,
                }

                local function most_urgent(states)
                	local best, best_rank = nil, nil
                	for _, state in ipairs(states) do
                		local rank = RANK[state]
                		if rank ~= nil and (best_rank == nil or rank < best_rank) then
                			best, best_rank = state, rank
                		end
                		end
                	return best
                end

                -- Running, or the last command's status; none before the first
                -- command.
                local function shell_state(pane)
                	if pane.exited ~= nil then
                		return "failed"
                	end
                	if pane.running ~= nil or pane.busy == true then
                		return "working"
                	end
                	if pane.last ~= nil then
                		if pane.last.status == 0 then
                			return "done"
                		end
                		return "failed"
                		end
                	return nil
                end

                -- The list refines the wait for input; the pane gives the rest.
                local function agent_state(pane, states)
                	local state = states[pane.pane]
                	if state == "working" then
                		return "working"
                		end
                	if state == "waiting_input" then
                		return "waiting"
                		end
                	if state == "exited" then
                		return "failed"
                		end
                	if state == "idle" then
                		return "done"
                		end
                	-- Without a list entry an exited pane is still a failure: a
                	-- dead agent must not read green.
                	if pane.exited ~= nil then
                		return "failed"
                	end
                	if pane.busy == true then
                		return "working"
                	end
                	return "done"
                end

                -- One rule: the letter, its colour, and a pulse for the
                -- live states.
                local function letter(selector, glyph, state)
                	local rule = ("%s { content: '%s'; color: %s; }"):format(selector, glyph, COLOUR[state])
                	if state == "waiting" or state == "working" then
                		rule = rule
                			.. (" %s { animation: tab-status-pulse 1.6s ease-in-out infinite; }"):format(selector)
                	end
                	return rule
                end

                -- The gates last installed; false until the first install,
                -- because an empty gate list is a real value.
                local last_gates = false

                -- The agent list costs ~21 ms against ~1.5 ms for panes and
                -- tabs, so it is read less often.
                local AGENT_EVERY_MS = 10000

                -- Cap on that gap under load: a stale wait-for-input beats a
                -- dead plugin.
                local AGENT_MAX_MS = 60000

                -- Agent states by pane, and when they were read. The clock
                -- starts now, so the first read waits a full gap.
                local agent_states = {}
                local last_agent_read = tern.now()

                -- Current gap: it doubles when a tick is slow, so a busy host
                -- slows the orange refresh instead of tripping the hook.
                local agent_gap = AGENT_EVERY_MS

                -- Gate rules from the pane list, the tab list and the cached
                -- agent states.
                local function compute_gates(cx, agents)
                	local panes = cx.session:panes()
                	local tabs = cx.session:tabs()

                	-- Each tab's panes, by kind; floating and parked panes
                	-- belong to none.
                	local shells, agents_of_tab = {}, {}
                	for _, pane in ipairs(panes) do
                		if pane.tab ~= nil and not pane.floating and not pane.parked then
                			if pane.kind == "agent" then
                				agents_of_tab[pane.tab] = agents_of_tab[pane.tab] or {}
                				table.insert(agents_of_tab[pane.tab], pane)
                			elseif pane.kind == "terminal" then
                				shells[pane.tab] = shells[pane.tab] or {}
                				table.insert(shells[pane.tab], pane)
                			end
                		end
                	end

                	-- A tab's shell and agent states, once per tab for both
                	-- layouts.
                	local states = {}
                	for _, tab in ipairs(tabs) do
                		local shell_states, agent_states = {}, {}
                		for _, pane in ipairs(shells[tab.id] or {}) do
                			local state = shell_state(pane)
                			if state ~= nil then
                				table.insert(shell_states, state)
                			end
                		end
                		for _, pane in ipairs(agents_of_tab[tab.id] or {}) do
                			local state = agent_state(pane, agents)
                			if state ~= nil then
                				table.insert(agent_states, state)
                			end
                		end
                		states[tab.id] = { most_urgent(shell_states), most_urgent(agent_states) }
                	end

                	-- Rail position: one group per session, tabs numbered inside
                	-- it, in tabs() order.
                	local row, count, seen, groups = {}, {}, {}, 0
                	for _, tab in ipairs(tabs) do
                		local session = tab.session or ""
                		if not seen[session] then
                			seen[session] = true
                			groups += 1
                			count[session] = 0
                		end
                		count[session] += 1
                		row[tab.id] = { group = groups, index = count[session] }
                	end

                	local gates = {}

                	for _, tab in ipairs(tabs) do
                		local where = row[tab.id]
                		if where ~= nil then
                			-- A host header shares the nav with the groups, so
                			-- `nth-child(k of .nav-group)` counts the groups
                			-- alone; plain `nth-child(k)` counts the headers too.
                			local rowsel = ("#sidebar > .tn-vt > :nth-child(%d of .nav-group) .nav-items > div > button.nav-row:nth-child(%d)"):format(
                				where.group,
                				where.index
                			)
                			local shell, agent = states[tab.id][1], states[tab.id][2]
                			if shell ~= nil then
                				gates[#gates + 1] = letter(rowsel .. " .tn-dk::before", "S", shell)
                			end
                			if agent ~= nil then
                				gates[#gates + 1] = letter(rowsel .. " .tn-dk::after", "A", agent)
                			end
                		end
                	end

                	-- The strip shows the current session alone, so number inside
                	-- it; the focused pane names that session without a daemon
                	-- round trip.
                	local current = nil
                	local focused = cx.session:focused()
                	if focused ~= nil then
                		for _, pane in ipairs(panes) do
                			if pane.pane == focused then
                				for _, tab in ipairs(tabs) do
                					if tab.id == pane.tab then
                						current = tab.session
                					end
                				end
                				break
                			end
                		end
                	end
                	if current == nil and cx.sessions ~= nil then
                		local ok, session = pcall(function()
                			return cx.sessions:current()
                		end)
                		if ok and session ~= nil then
                			current = session.id
                		end
                	end
                	local face = 0
                	for _, tab in ipairs(tabs) do
                		if current == nil or tab.session == current then
                			face += 1
                			local tabsel = ("#tabbar .tb-tabs > .tt:nth-of-type(%d) .fc"):format(face)
                			local shell, agent = states[tab.id][1], states[tab.id][2]
                			if shell ~= nil then
                				gates[#gates + 1] = letter(tabsel .. "::before", "S", shell)
                			end
                			if agent ~= nil then
                				gates[#gates + 1] = letter(tabsel .. "::after", "A", agent)
                			end
                		end
                	end

                	return table.concat(gates, "\n")
                end

                -- Install the sheet when the gates changed: it is a restyle of
                -- the whole window, so it never runs with the reads. A failed
                -- install keeps the old sheet and is retried.
                local function install(sheet)
                	local ok = pcall(function()
                		tern.css("ui", CSS .. "\n" .. sheet)
                	end)
                	if not ok then
                		tern.log.warn("tern tab status: the sheet did not install")
                		return
                	end
                	last_gates = sheet
                end

                -- The expensive read (~21 ms): every session's agent blocks. A
                -- failure keeps the last good states and backs the gap off.
                local function read_agents(cx)
                	local ok, list = pcall(function()
                		return cx.agents:list()
                	end)
                	if not ok or list == nil then
                		tern.log.warn("tern tab status: the agent list failed: " .. tostring(list))
                		agent_gap = agent_gap * 2
                		if agent_gap > AGENT_MAX_MS then
                			agent_gap = AGENT_MAX_MS
                		end
                		return
                	end
                	local states = {}
                	for _, agent in ipairs(list) do
                		states[agent.pane] = agent.state
                	end
                	agent_states = states
                	last_agent_read = tern.now()
                end

                -- Half a second: a slower tick waits in the queue less often,
                -- and the events react sooner anyway.
                local TICK_MS = 500

                -- The last tick's time; the events use it to tell a live timer
                -- from a dead one.
                local last_timer_tick = 0

                -- A tick older than this means the timer is dead and the event
                -- does the work.
                local STALE_MS = 2000

                -- The cheap work (~1.5 ms): panes, tabs and the install, from
                -- the cached agent states. A cache older than AGENT_MAX_MS is
                -- dropped; the pane fields cover the rest.
                local function work(fresh)
                	if fresh == nil then
                		return
                	end
                	local states = agent_states
                	if (tern.now() - last_agent_read) >= AGENT_MAX_MS then
                		states = {}
                	end
                	local ok, sheet = pcall(compute_gates, fresh, states)
                	if not ok then
                		tern.log.warn("tern tab status: the state read failed: " .. tostring(sheet))
                	elseif sheet ~= last_gates then
                		install(sheet)
                	end
                end

                -- The timer; it arms the next tick first, so a kill mid-tick
                -- cannot end the chain. It carries the agent read, not the
                -- events: a trip there would kill every handler at once.
                local function poll(fresh)
                	tern.timer(TICK_MS, poll)
                	local entered = tern.now()
                	-- How late this tick ran. The wait happens before the
                	-- callback, so only the gap between ticks shows it.
                	local drift = 0
                	if last_timer_tick ~= 0 then
                		drift = entered - last_timer_tick - TICK_MS
                	end
                	last_timer_tick = entered
                	if fresh ~= nil and (entered - last_agent_read) >= agent_gap then
                		read_agents(fresh)
                	end
                	work(fresh)
                	-- The work of the tick itself, on top of the wait.
                	local spent = tern.now() - entered
                	-- A late or slow tick means a busy thread: double the agent
                	-- gap, otherwise halve it back.
                	if drift > 20 or spent > 35 then
                		agent_gap = agent_gap * 2
                		if agent_gap > AGENT_MAX_MS then
                			agent_gap = AGENT_MAX_MS
                		end
                	elseif drift < 20 and spent < 35 then
                		agent_gap = agent_gap // 2
                		if agent_gap < AGENT_EVERY_MS then
                			agent_gap = AGENT_EVERY_MS
                		end
                	end
                end
                tern.timer(TICK_MS, poll)

                -- The second driver, and the one a trip cannot disable: it does
                -- the work when the timer is quiet, and reads the agent list
                -- only when that cache is badly stale.
                for _, event in { "focus", "title", "pane_created", "pane_closed" } do
                	tern.on(event, function(_ev, cx)
                		-- The timer is alive and did the work already.
                		if last_timer_tick ~= 0 and (tern.now() - last_timer_tick) < STALE_MS then
                			return
                		end
                		-- The timer is dead: this event carries the work.
                		if cx ~= nil and (tern.now() - last_agent_read) >= AGENT_MAX_MS then
                			read_agents(cx)
                		end
                		work(cx)
                	end)
                end
              '';
        in
        pkgs.runCommand "tern-tab-status-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
