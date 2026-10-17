{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-tab-status: the pane-state indicator at the right end of each
      # tab, so an agent's state reads at a glance:
      #
      #   waiting for input - orange, pulsing
      #   working           - purple, pulsing
      #   failed/inactive   - red, steady
      #   finished          - green, steady
      #
      # Tern draws the indicators itself and colours them through --st from
      # data-st, in two shapes the sheet must both reach:
      #
      # - Float, Tiles and the horizontal tab bar: a face icon
      #   (`#tabbar .tt > .fc > .tn-face[data-st]`), moved after the title.
      # - Rail and vertical tabs: a dot on each pane tile's corner
      #   (`#sidebar .tn-vt .nav-row .tn-dk-c[data-st]::after`), with the
      #   pane-icon deck moved to the row's right end and the tiles' glyphs
      #   hidden, so only the dots are left.
      #
      # The dots exist only for panes Tern calls agents. Tern records
      # state for every pane, shells included (a running or failed
      # command), so the window half hides the dots of tabs that hold no
      # agent pane: terminal, plugin and native-block panes alone show
      # nothing. A tab that holds an agent pane keeps every stateful
      # pane's dot, a busy shell included.
      #
      # The gate is per tab, because a tile cannot name its pane. The
      # deck holds one tile per tiled pane, but in focus order (Tern
      # moves the focused pane's tile last, 0.6.2 changelog: "tabs with
      # several panes show the other panes' icons before the focused
      # one's"), and a tile carries no pane identity: `[id]`, `[data-pan]`,
      # `[title]` and `[style]` all match no tile (verified against
      # 0.9.3). A tile index therefore lands on whichever pane holds
      # that slot now, and the dot followed the focused pane.
      #
      # The whole sheet is installed with `tern.css` from the window half
      # rather than the manifest: a manifest sheet's rules for `::after`
      # stayed stale until another sheet forced a restyle, while `tern.css`
      # is re-installed on every rebuild call.
      packages.tern-tab-status-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-tab-status-plugin.toml" {
            schema = 1;
            id = "tab-status";
            name = "tern-tab-status";
            version = "0.1.0";
            description = "Pane state at the right end of each tab: orange waiting, purple working, red failed, green finished.";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-tab-status-init.luau" # luau
              ''
                --!nonstrict

                local CSS = [==[
                /* Horizontal tabs: .fc holds the face and leads the tab. */
                #tabbar .tt > .fc {
                	order: 999;
                	flex: none;
                	margin-left: auto;
                }

                /* Vertical tabs: the pane-icon deck holds the state dots.
                   order moves it past the label, the meta column and the
                   colour chip. */
                .tn-vt .nav-row > .tn-dk {
                	order: 999;
                	margin-left: auto;
                }

                #tabbar .tt .tn-face {
                	color: var(--st);
                }

                /* The tiles carry a program icon and a per-pane colour. Hide
                   their fill, glyph and working shimmer, so the state dot is
                   all that is left of the deck. Only named children are
                   hidden: `> *` also hides the dot pseudo-element. */
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

                /* Every tile is collapsed onto its deck's box, so the dots
                   line up whatever the pane index Tern scales and offsets
                   them by. !important, because Tern's per-index rules
                   (`.tn-dk.col .tn-dk-c.d1`) outrank a plugin selector. */
                .tn-vt .nav-row .tn-dk-c {
                	left: 0 !important;
                	top: 0 !important;
                	width: 100%;
                	height: 100%;
                	transform: none !important;
                }

                /* The dot: one size for every pane, centred on the deck
                   (which the row centres) and inset from the row's right
                   edge by the same 9px the label has on the left (the row
                   pads 10px; the dot starts inside the deck's 7.4px tail). */
                .tn-vt .nav-row .tn-dk-c[data-st]::after {
                	right: 2px;
                	bottom: auto;
                	top: 50%;
                	margin-top: -4.5px;
                	width: 9px;
                	height: 9px;
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
                   still, so green does not blink. */
                @keyframes tab-status-pulse {
                	0%,
                	100% {
                		opacity: 1;
                	}
                	50% {
                		opacity: 0.35;
                	}
                }

                #tabbar .tt .tn-face[data-st='waiting'],
                #tabbar .tt .tn-face[data-st='working'] {
                	animation: tab-status-pulse 1.6s ease-in-out infinite;
                }

                .tn-vt .nav-row .tn-dk-c[data-st='waiting']::after,
                .tn-vt .nav-row .tn-dk-c[data-st='working']::after {
                	animation: tab-status-pulse 1.6s ease-in-out infinite;
                }

                #tabbar .tt .tn-face[data-st='done'],
                .tn-vt .nav-row .tn-dk-c[data-st='done']::after {
                	animation: none;
                }

                /* Waiting for input. */
                #tabbar .tt .tn-face[data-st='waiting'],
                .tn-vt .nav-row .tn-dk-c[data-st='waiting'] {
                	--st: var(--warn);
                }

                /* Working. No theme variable carries purple, so it is
                   literal. */
                #tabbar .tt .tn-face[data-st='working'],
                .tn-vt .nav-row .tn-dk-c[data-st='working'] {
                	--st: #b48cf2;
                }

                /* Error or inactive: red, and no pulse. */
                #tabbar .tt .tn-face[data-st='failed'] {
                	--st: var(--bad);
                	animation: none;
                }

                .tn-vt .nav-row .tn-dk-c[data-st='failed'] {
                	--st: var(--bad);
                }

                .tn-vt .nav-row .tn-dk-c[data-st='failed']::after {
                	animation: none;
                }

                /* Finished. */
                #tabbar .tt .tn-face[data-st='done'],
                .tn-vt .nav-row .tn-dk-c[data-st='done'] {
                	--st: var(--ok);
                }

                @media (prefers-reduced-motion: reduce) {
                	#tabbar .tt .tn-face,
                	.tn-vt .nav-row .tn-dk-c[data-st]::after {
                		animation: none;
                	}
                }
                ]==]

                local function rebuild(cx)
                	local panes = cx.session:panes()
                	local tabs = cx.session:tabs()

                	local tiled = {}
                	for _, pane in panes do
                		if pane.tab ~= nil and not pane.floating and not pane.parked then
                			tiled[pane.tab] = tiled[pane.tab] or {}
                			table.insert(tiled[pane.tab], pane.kind)
                		end
                	end

                	-- Row position: sessions stack as groups, tabs number
                	-- within their group, in the order tabs() lists them.
                	local row, count, seen, groups = {}, {}, {}, 0
                	for _, tab in tabs do
                		local session = tab.session or ""
                		if not seen[session] then
                			seen[session] = true
                			groups += 1
                			count[session] = 0
                		end
                		count[session] += 1
                		row[tab.id] = { group = groups, index = count[session] }
                	end

                	-- A tab keeps its state marks only while it holds an agent
                	-- pane. The gate is per tab, never per tile: a tile carries
                	-- no pane name (see the header).
                	local function has_agent(tab)
                		for _, kind in tiled[tab.id] or {} do
                			if kind == "agent" then
                				return true
                			end
                		end
                		return false
                	end

                	local gates = {}
                	-- Horizontal layouts draw one face per tab, for that tab's
                	-- focused pane: keep the group only for a tab with an agent.
                	-- tabs() spans every session, but the tab strip shows only
                	-- the current one, so number inside that session alone.
                	local current = nil
                	if cx.sessions ~= nil then
                		local ok, session = pcall(function()
                			return cx.sessions:current()
                		end)
                		if ok and session ~= nil then
                			current = session.id
                		end
                	end
                	local face = 0
                	for _, tab in tabs do
                		if current == nil or tab.session == current then
                			face += 1
                			if not has_agent(tab) then
                				gates[#gates + 1] = ("#tabbar .tb-tabs > .tt:nth-of-type(%d) .fc { display: none }"):format(face)
                			end
                		end
                	end
                	for _, tab in tabs do
                		local where = row[tab.id]
                		if where ~= nil and not has_agent(tab) then
                			-- Rows are buttons inside one wrapper, so the row
                			-- index goes on the button, not on a wrapper. The
                			-- whole row is gated: no tile index, no pane name.
                			local rowsel = ("#sidebar > .tn-vt > .nav-group:nth-child(%d) .nav-items > div > button.nav-row:nth-child(%d)"):format(
                				where.group,
                				where.index
                			)
                			gates[#gates + 1] = rowsel .. " .tn-dk-c::before, " .. rowsel .. " .tn-dk-c::after { display: none }"
                		end
                	end
                	tern.css("ui", CSS .. "\n" .. table.concat(gates, "\n"))
                end

                tern.on("window_start", function(cx)
                	rebuild(cx)
                end)

                -- Titles change constantly (every agent frame), and a full
                -- sheet reinstall on each event trips the 50 ms hook budget,
                -- which disables the hook until reload. Coalesce bursts.
                local pending = nil
                local function schedule()
                	if pending ~= nil then
                		return
                	end
                	pending = tern.timer(150, function(fresh)
                		pending = nil
                		if fresh ~= nil then
                			rebuild(fresh)
                		end
                	end)
                end

                for _, event in { "focus", "pane_created", "pane_closed", "tab_created", "tab_closed", "title" } do
                	tern.on(event, function(_ev, _cx)
                		schedule()
                	end)
                end

                -- A reload lands after window_start, so the first sheet is
                -- built from a one-shot timer, whose callback gets a cx.
                tern.timer(0, function(cx)
                	if cx ~= nil then
                		rebuild(cx)
                	end
                end)
              '';
        in
        pkgs.runCommand "tern-tab-status-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
