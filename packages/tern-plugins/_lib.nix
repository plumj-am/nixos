# Shared Luau for the tern-plugins packages. outputs.nix skips any path holding
# "/_", so this file is not pulled into the flake's module tree.
{
  # tern 0.5.2 keeps plugin commands in the keymap but out of the action registry, so
  # `cx.action("plugin.ide.layout")` answers "Unknown action"; inlining is the only way to share.
  # Callers use `ide_layout_apply(cx, pane)` and `ide_layout_pane(cx)`; locals are prefixed to avoid clashes.
  ideLayout = # luau
    ''
      local IDE_TOP_RATIO = 0.75
      local IDE_LEFT_RATIO = 0.68
      -- No IDE_AGENT_COMMAND: the native agent uses
      -- agent_command from tern's settings.

      -- TabTree node: a leaf is {pane=...}; else a split with [1], [2] and a `split` axis.
      -- The leaf's parent IS the divider that resizes it; a "has children" match would pick a nested divider.
      local function ide_parent_of(node, pane)
        if node == nil or node.pane ~= nil then
          return nil
        end

        local left, right = node[1], node[2]
        if left == nil or right == nil then
          return nil
        end

        if left.pane == pane then
          return { node = node, first = true }
        elseif right.pane == pane then
          return { node = node, first = false }
        end

        return ide_parent_of(left, pane) or ide_parent_of(right, pane)
      end

      -- `split` here is "right"/"down", not the "Row"/"Column" axis `tern inspect` prints.
      -- resize grows a pane toward dir (toward its sibling), so widening means growing away.
      local function ide_grow_across(split, is_first)
        if split == "right" then
          return is_first and "right" or "left"
        end
        return is_first and "down" or "up"
      end

      local function ide_share_of(found)
        if found.first then
          return found.node.ratio
        end
        if found.node.ratio == nil then
          return nil
        end
        return 1 - found.node.ratio
      end

      -- Cell size is not exposed window-side (PaneInfo has no cell fields, BlockCx.cols/rows is host-only).
      -- A 1-cell probe measures the axis; resize(pane, probe, -1) is its exact inverse.
      local function ide_nudge(cx, pane, split, want)
        local function measure()
          local tab = cx.session:tab_of(pane)
          if tab == nil then
            return nil, nil
          end

          local tree = cx.session:layout(tab)
          if tree == nil then
            return nil, nil
          end

          local found = ide_parent_of(tree.root, pane)
          if found == nil or found.node.split ~= split then
            return nil, nil
          end

          return ide_share_of(found), found
        end

        local here = measure()
        if here == nil or math.abs(here - want) < 0.005 then
          return
        end

        local probe = ide_grow_across(split, true)
        if not cx.layout:resize(pane, probe, 1) then
          return
        end

        local after = measure()
        if after == nil or after == here then
          return
        end

        local per_cell = math.abs(after - here)
        if per_cell <= 0 then
          return
        end

        if not cx.layout:resize(pane, probe, -1) then
          return
        end

        local restored = measure()
        if restored == nil then
          return
        end

        local cells = math.floor((want - restored) / per_cell + 0.5)
        if cells == 0 then
          return
        end

        if (cells > 0) == (after > here) then
          cx.layout:resize(pane, probe, cells)
        else
          cx.layout:resize(pane, probe, -cells)
        end
      end

      -- Focused pane, else the window's first (headless).
      local function ide_layout_pane(cx)
        local pane = cx.session:focused()
        if pane ~= nil then
          return pane
        end
        for _, other in ipairs(cx.session:panes()) do
          return other.pane
        end
        return nil
      end

      -- The layout as a list of steps.
      --
      -- Each step is one pass over the window's UI thread, and each pass
      -- has its own 50 ms budget. The steps share a state table, because
      -- a step cannot see what a later one produced: the split's pane id
      -- is only known after the split ran.
      --
      -- Split down before right, else the tree comes out three-region;
      -- focus = false keeps the caller's pane.
      local function ide_layout_steps(pane)
        local state = { pane = pane, south = nil }
        return {
          function(cx)
            if state.pane == nil then
              return false
            end
            local south = cx.layout:split(state.pane, "down", nil, { focus = false })
            if south == nil then
              return false
            end
            state.south = south
            ide_nudge(cx, state.pane, "down", IDE_TOP_RATIO)
            return true
          end,
          -- A native agent pane, not a shell running omp: the built-in
          -- `new_agent_block` command opens one beside the focused pane
          -- (top-right here), using agent_command from tern's settings
          -- and the focused pane's cwd. It sends no prompt, so the
          -- agent tab starts empty.
          function(cx)
            if state.pane == nil then
              return false
            end
            cx:action("new_agent_block")
            ide_nudge(cx, state.pane, "right", IDE_LEFT_RATIO)
            return true
          end,
          function(cx)
            if state.south == nil then
              return false
            end
            local br = cx.layout:split(state.south, "right", nil, { focus = false })
            if br == nil then
              return false
            end
            cx.layout:focus(state.pane)
            return true
          end,
        }
      end

      -- The layout in one pass. Kept for callers that already run
      -- inside a step of their own.
      local function ide_layout_apply(cx, pane)
        if pane == nil then
          return false
        end

        local south = cx.layout:split(pane, "down", nil, { focus = false })
        if south == nil then
          return false
        end
        ide_nudge(cx, pane, "down", IDE_TOP_RATIO)

        -- A native agent pane, not a shell running omp: the built-in
        -- `new_agent_block` command opens one beside the focused pane
        -- (top-right here), using agent_command from tern's settings
        -- and the focused pane's cwd. It sends no prompt, so the
        -- agent tab starts empty.
        cx:action("new_agent_block")
        ide_nudge(cx, pane, "right", IDE_LEFT_RATIO)

        local br = cx.layout:split(south, "right", nil, { focus = false })
        if br == nil then
          return false
        end

        cx.layout:focus(pane)
        return true
      end
    '';

  # A window half's hook has 50 ms, and every `cx.session` and `cx.layout`
  # call marshals IPC to the daemon. A command that splits, resizes and
  # focuses does that work in one pass, and the pass bills all of it to
  # the hook that started it: "command layout exceeded 50 ms".
  #
  # `stepped` runs a list of steps, one per hook pass. Each step gets a
  # fresh cx, so no step can hold a stale one, and a step that raises
  # stops the chain instead of taking the rest of the budget with it.
  #
  # Callers use `stepped(steps, on_done)`; the locals are prefixed so
  # inlined copies cannot clash with a caller's own names.
  stepped = # luau
    ''
      -- One step per pass. `sleep(0)` re-arms the chain as its own
      -- `await` hook, so the next step gets a fresh 50 ms budget.
      local function stepped(steps, on_done)
        local index = 0

        local function run(_result, _err, cx)
          index = index + 1
          local step = steps[index]
          if step == nil then
            if on_done ~= nil then
              on_done(cx, true)
            end
            return
          end

          local ok, err = pcall(step, cx)
          if not ok then
            tern.log.warn("tern stepped: a step failed: " .. tostring(err))
            if on_done ~= nil then
              on_done(cx, false)
            end
            return
          end

          if index < #steps then
            -- The next step is its own pass, so it gets its own budget.
            tern.sleep(0):next(run)
          elseif on_done ~= nil then
            on_done(cx, true)
          end
        end

        tern.sleep(0):next(run)
      end
    '';
}
