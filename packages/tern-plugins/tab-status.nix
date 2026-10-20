{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-tab-status: the task indicator at the right end of each tab,
      # so an agent's state reads at a glance:
      #
      #   S - a shell task, A - an agent task
      #
      # One letter per kind per tab, whatever the number of panes. The
      # letter takes the state colour of the most urgent task of its kind:
      #
      #   waiting for input - orange, pulsing
      #   working           - purple, pulsing
      #   failed/inactive   - red, steady
      #   finished          - green, steady
      #
      # The letters replace the state dots this plugin drew before. A
      # letter stands for the kind of task, the colour for its state.
      #
      # The window half computes both halves itself, from the pane list
      # and the agent list, and writes one rule per tab per letter. The
      # rules are per tab, never per pane, because a tab can hold several
      # panes of a kind and only one letter is drawn.
      #
      # The states come from what Tern records, not from the DOM:
      #
      # - A shell pane has state while a command runs (`running`, `busy`),
      #   when the last command failed (`last.status` not 0) or when it
      #   succeeded (`last.status` 0). A shell that never ran a command
      #   has no state and draws no letter.
      # - An agent pane has the state the agent list reports: working,
      #   waiting for input, exited, or idle, which is a finished turn.
      #
      # When a tab holds several tasks of a kind, the most urgent state
      # wins: waiting over working over failed over finished.
      #
      # The rules reach two shapes of the tab chrome:
      #
      # - Rail and vertical tabs: the letters ride the pane-icon deck at
      #   the row's right end (`#sidebar .tn-vt .nav-row .tn-dk`). The
      #   tiles' glyphs and their state dots are hidden, so the letters
      #   are all that is left of the deck.
      # - Float, Tiles and the horizontal tab bar: the letters ride the
      #   face container at the tab's right end (`#tabbar .tt > .fc`),
      #   which holds Tern's own face icon. That face is hidden: the
      #   letters are the only tab indicator.
      #
      # The whole sheet is installed with `tern.css` from the window half
      # rather than the manifest: a manifest sheet's rules for `::after`
      # stayed stale until another sheet forced a restyle, while `tern.css`
      # is re-installed on every rebuild call.
      #
      # The window half has no `window_start` handler. That hook runs while
      # the window is still busy, and the rebuild inside it tripped the
      # 50 ms budget, which disabled the hook until the next reload: a
      # freshly opened window showed no letters at all. A timer drives the
      # work instead.
      #
      # The timer hook reads the state and installs the sheet. It has to
      # stay inside its 50 ms budget, because a hook that blows its budget
      # is disabled until the next reload and the letters freeze for good.
      # So the reads it does are the cheap ones: the pane list and the tab
      # list, about 1.5 ms together. The agent list, which costs about
      # 21 ms because it walks the agent blocks of every session, is read
      # every ten seconds, and it only refines the one agent state the
      # pane cannot give: the wait for input.
      #
      # The budget is wall clock, from the dispatch, so Tern charges this
      # plugin for the stalls of the shared VM thread. A hook that waits
      # behind another plugin's long call trips even when its own work is
      # a millisecond, and a trip disables the hook until the next
      # reload. A tripped timer is gone for good: the plugin's other
      # timers do not come back either. So the work has two drivers, and
      # each can do it alone: the timer, and the window events. An event
      # that finds the timer gone quiet does the work itself, and the
      # letters come back without a reload. The events carry only the
      # cheap reads, so a trip in the events cannot happen either.
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
                /* Vertical tabs: the deck at the row's right end holds the
                   letters. The tiles stay as empty boxes (Tern's pane icons
                   live in them, and the pip marker with them), so the
                   letters are the whole indicator. */
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

                /* Horizontal tabs: the face container takes the tab's right
                   end and holds the letters. Tern's own face is gone: the
                   letters are the only tab indicator. */
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

                /* The letters: one per kind, in the mono face. */
                .tn-vt .nav-row > .tn-dk::before,
                .tn-vt .nav-row > .tn-dk::after,
                #tabbar .tt > .fc::before,
                #tabbar .tt > .fc::after {
                	font: 700 10px/1 var(--mono);
                }

                /* The tiles carry a program icon and a per-pane colour. Hide
                   their fill, glyph and working shimmer, and the state dot
                   the letters replace. Only named children are hidden:
                   `> *` also hides the dot pseudo-element. */
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

                /* Every tile is collapsed onto its deck's box, so nothing
                   of it shifts the letters. !important, because Tern's
                   per-index rules (`.tn-dk.col .tn-dk-c.d1`) outrank a
                   plugin selector. */
                .tn-vt .nav-row .tn-dk-c {
                	left: 0 !important;
                	top: 0 !important;
                	width: 100%;
                	height: 100%;
                	transform: none !important;
                }

                /* Key hints: the tab-number pill and the keymap-prefix hint
                   (`.meta.keys`), which the rail reveals while a modifier is
                   held, plus the horizontal tab bar's `.mk.keys`. Hidden in
                   both states: the bindings still work, only the labels go. */
                .tn-vt .nav-row .kbd.tn-num,
                .tn-vt .nav-row .meta,
                #tabbar .tt .kbd.tn-num,
                #tabbar .tt .mk.keys {
                	display: none;
                }

                /* One pulse for the live states; Tern's own working animation
                   is slower and only covers working. A finished tab holds
                   still, so green does not blink.

                   The pulse rule in the gate list has an id in its
                   selector, so it outranks this one. `!important` puts
                   this rule above any gate rule, and reduced motion is
                   honoured. */
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

                -- The colour of a state. No theme variable carries purple,
                -- so that one is literal.
                local COLOUR = {
                	waiting = "var(--warn)",
                	working = "#b48cf2",
                	failed = "var(--bad)",
                	done = "var(--ok)",
                }

                -- How urgent a state is. The most urgent state of a kind
                -- decides the letter's colour.
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

                -- The state of a shell pane. A shell has state while a
                -- command runs, and after a command finished, but not
                -- before it ever ran one.
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

                -- The state of an agent pane.
                --
                -- The pane list gives most of it for free: an agent that
                -- is working is busy, and an agent that ended its turn
                -- is idle. Only the wait for input is not in the pane,
                -- so the agent list refines that one case, and it does so
                -- on a slow cadence of its own.
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
                	-- No list entry: fall back to the pane's own fields.
                	-- An exited pane is a failure even without a list
                	-- entry. Without this, an agent that died leaves a
                	-- green "done" letter, which says the opposite of
                	-- what happened.
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

                -- The static sheet never changes; only the gates below it
                -- do. Installing the whole sheet on every rebuild made the
                -- window restyle on every title event, and a restyle is
                -- what makes the next frame slow: the chrome formatter
                -- then trips its 4 ms budget, because it runs while the
                -- window builds a frame.
                --
                -- So the sheet is one sheet, as it was, and it is
                -- installed only when a gate changed. The gates stay in
                -- the same sheet as the rules they override, so their
                -- order inside it does not change.
                --
                -- The last gate string the plugin saw, so a rebuild
                -- that reads the same state installs nothing. It is set
                -- only after the install worked. A sentinel, not nil:
                -- an empty gate list is a real value.
                local last_gates = false

                -- The gate rules for the current state.
                --
                -- The reads come in two parts, because they cost very
                -- different amounts. The pane list and the tab list are
                -- cheap: about 1.5 ms together. The agent list is
                -- expensive: about 21 ms in a live window, because it
                -- walks the agent blocks of every session.
                --
                -- The agent state that the pane cannot give is the wait
                -- for input, so the agent list is read and its result is
                -- a cache the next read uses. The gap between two reads
                -- is ten seconds, and it grows to a minute when the
                -- thread is busy, then comes back down. Ten seconds is
                -- slow enough that the read does not sit in the timer
                -- hook's way, and the wait for input does not need to be
                -- fresher than that.
                local AGENT_EVERY_MS = 10000

                -- The longest the agent list may go unread. A host under
                -- load reads it more rarely, and the wait for input goes
                -- stale rather than the plugin dying.
                local AGENT_MAX_MS = 60000

                -- The agent states, by pane, and when they were read.
                -- The clock starts now, so the first read waits a full
                -- gap instead of landing in the busy moment the window
                -- opens in.
                local agent_states = {}
                local last_agent_read = tern.now()

                -- The gap between two agent reads. It grows when a tick
                -- took most of the hook budget and goes back to the base
                -- when a tick was quick, so a busy host slows the orange
                -- refresh down instead of tripping the hook that carries
                -- it.
                local agent_gap = AGENT_EVERY_MS

                -- The gate rules for the current state, from the pane
                -- list, the tab list and the cached agent states.
                local function compute_gates(cx, agents)
                	local panes = cx.session:panes()
                	local tabs = cx.session:tabs()

                	-- The panes of each tab, by kind. Floating and parked
                	-- panes belong to no tab.
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

                	-- The state of a tab's shell task and of its agent task.
                	-- Computed once per tab: the two layouts below ask for
                	-- the same states.
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

                	-- Row position: sessions stack as groups, tabs number
                	-- within their group, in the order tabs() lists them.
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

                	-- The vertical list shows the tabs of a session as rows,
                	-- one per tab, in the order tabs() lists them.
                	for _, tab in ipairs(tabs) do
                		local where = row[tab.id]
                		if where ~= nil then
                			-- Rows are buttons inside one wrapper, so the row
                			-- index goes on the button, not on a wrapper.
                			local rowsel = ("#sidebar > .tn-vt > .nav-group:nth-child(%d) .nav-items > div > button.nav-row:nth-child(%d)"):format(
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

                	-- Horizontal layouts draw one face per tab. tabs() spans
                	-- every session, but the tab strip shows only the current
                	-- one, so number inside that session alone.
                	--
                	-- The current session is the one the focused pane is in.
                	-- Reading it from the focused pane costs nothing; the
                	-- session call costs a round trip to the daemon, and it
                	-- was the most expensive read in this pass.
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

                	-- The sheet is installed only when a gate changed. A
                	-- title event fires on every agent frame, and
                	-- reinstalling on each one restyled the window every
                	-- time: "title exceeded 50 ms", and the slow frames
                	-- that followed tripped the chrome formatter too.
                	return table.concat(gates, "\n")
                end

                -- Install the sheet, if the gates changed. The install
                -- is a restyle of the whole window, so it happens in
                -- its own pass and never together with the reads.
                --
                -- The sheet is only marked as installed when the call
                -- worked. A failed install leaves the old sheet in
                -- place, and the next tick tries again.
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

                -- Read the agent states. This is the expensive read: it
                -- lists the agent blocks of every session, and it costs
                -- about 21 ms in a live window.
                --
                -- The gap to the next read follows the load of the
                -- thread, and the tick measures that load. A host that
                -- is busy makes the wait for input go stale, which is a
                -- small wrongness, and not a dead plugin, which is a
                -- large one.
                --
                -- A failure here is not fatal: the cache keeps the last
                -- good states, and the pane fields give the rest. The
                -- letters stay correct enough, and the next read tries
                -- again.
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

                -- The gap between two ticks.
                --
                -- The tick is half a second. The reads are cheap, about
                -- 1.5 ms, but the budget is wall clock from the
                -- dispatch, so a hook that waits behind another
                -- plugin's long call trips even when its own work is
                -- small. A slower tick waits in the queue less often,
                -- and the events make the letters react sooner anyway.
                local TICK_MS = 500

                -- The time of the last timer tick. The events compare
                -- against it: the timer is alive when it is recent, and
                -- the events stay out of its way. The timer also
                -- compares against it, to find the drift.
                local last_timer_tick = 0

                -- The self-heal.
                --
                -- Tern charges every plugin for the stalls of the shared
                -- VM thread: the hook budget is wall clock, from the
                -- dispatch, so a hook that waits behind another plugin's
                -- long call trips even when its own work is a
                -- millisecond. A hook that trips is disabled until the
                -- next reload.
                --
                -- A tripped timer is gone for good. The plugin's other
                -- timers do not come back either, and a timer armed from
                -- an event does not come back either: the whole plugin's
                -- timers stop when one of them trips. So the work has two
                -- drivers that can each do it alone.
                --
                -- The timer is the first driver. The window events are
                -- the second, and they are the one that survives: a
                -- disabled timer hook does not disable them. An event
                -- that finds the timer gone quiet does the work itself,
                -- and the letters come back without a reload.
                --
                -- The event fires often, so the check is cheap: a
                -- comparison of two numbers.
                local STALE_MS = 2000

                -- The cheap work: the pane list, the tab list and the
                -- install. It takes about 1.5 ms, and it uses only the
                -- cached agent states.
                --
                -- The agent list is not read here. It costs about 21 ms,
                -- and a hook that carries it can trip, and a tripped
                -- hook is disabled until the next reload. The read
                -- belongs in the timer, which is the driver that can be
                -- replaced, and not in the events, which are the last
                -- line of defence.
                --
                -- A cache older than `AGENT_MAX_MS` is not used. It
                -- would keep the state of an agent that has since
                -- moved on, and a wrong colour is worse than a missing
                -- one. The pane fields give the state that the cache
                -- cannot: an agent that is busy is working, and one that
                -- is not is done. Only the wait for input is lost.
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

                -- The timer. It arms the next tick first, so a kill in
                -- the middle of a tick cannot end the chain.
                --
                -- The agent list is read here, on the gap the backoff
                -- set. The timer carries that read and not the events,
                -- because the events are the last line of defence: a
                -- trip in an event hook would kill every event handler
                -- at once, and the plugin would have no driver left.
                local function poll(fresh)
                	tern.timer(TICK_MS, poll)
                	local entered = tern.now()
                	-- The drift: how late this tick was called.
                	--
                	-- The timer asks for a tick every `TICK_MS`, so the
                	-- gap between the start of this tick and the start
                	-- of the last one is the wait. The budget is wall
                	-- clock from the dispatch, and the wait for the
                	-- shared VM thread happens before the callback
                	-- starts, so a clock read inside the callback cannot
                	-- see it. The drift between two ticks can.
                	--
                	-- This is the signal that matters: it is what the
                	-- budget is spent on, and it is what a trip is.
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
                	-- A tick that waited, or one that took long, means
                	-- the thread is busy, so the next agent read waits
                	-- longer. A busy host then shows a stale wait for
                	-- input, a small wrongness, instead of a dead
                	-- plugin, a large one.
                	if drift > 20 or spent > 35 then
                		agent_gap = agent_gap * 2
                		if agent_gap > AGENT_MAX_MS then
                			agent_gap = AGENT_MAX_MS
                		end
                	elseif drift < 20 and spent < 35 then
                		-- The gap halves back down, one step at a time. A
                		-- plain reset would leave the gap parked at
                		-- whatever it had climbed to, because a tick that
                		-- is neither busy nor quick would keep it there.
                		-- The gap has to come back down, or the wait for
                		-- input would stop refreshing under the constant
                		-- load of the other plugins.
                		agent_gap = agent_gap // 2
                		if agent_gap < AGENT_EVERY_MS then
                			agent_gap = AGENT_EVERY_MS
                		end
                	end
                end
                tern.timer(TICK_MS, poll)

                -- The events. They are the second driver of the work, and
                -- they are the one that survives a trip.
                --
                -- A tripped timer hook is dead until the next reload, and
                -- a timer armed from an event does not come back either:
                -- the whole plugin's timers stop when one of them trips.
                -- So the events do not arm a timer. They do the work
                -- themselves, and they do it when the timer has gone
                -- quiet, so the two drivers never do the same work twice
                -- in a row.
                --
                -- When the events take over, they also take over the
                -- agent list, because the timer that read it is gone.
                -- Without that, the wait for input would freeze on the
                -- last state the timer saw.
                --
                -- The events read it only when the cache is badly stale,
                -- at `AGENT_MAX_MS`. A `title` event fires on every
                -- agent frame, so a 21 ms read in it would run
                -- constantly, and a trip there would kill every event
                -- handler at once: the plugin would have no driver left.
                -- The timer reads it on the shorter gap, and the events
                -- only step in when the timer is gone.
                --
                -- The events that fire are the ones worth having: focus
                -- and title, and the pane events. The command events did
                -- not fire in a live window, so they are not counted on.
                for _, event in { "focus", "title", "pane_created", "pane_closed" } do
                	tern.on(event, function(_ev, cx)
                		-- The timer is alive: it did the work already, and
                		-- doing it again would be a wasted read.
                		if last_timer_tick ~= 0 and (tern.now() - last_timer_tick) < STALE_MS then
                			return
                		end
                		-- The timer is dead: this event carries the work.
                		-- The agent list is read here only when the cache
                		-- is badly stale, so the event hook stays cheap
                		-- in the normal case.
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
