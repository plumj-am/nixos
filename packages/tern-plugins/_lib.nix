# Shared Luau for the tern-plugins packages. outputs.nix skips any path holding
# "/_", so this file is not pulled into the flake's module tree.
{
  # The IDE four-cell layout, inlined into every plugin that wants it.
  #
  # A plugin cannot call another plugin's `tern.command` by name: tern 0.5.2
  # keeps plugin commands in the keymap but out of the action registry, so
  # `cx.action("plugin.ide.layout")` answers "Unknown action" even inside the
  # plugin that registered it. Inlining the code is the only way to share it.
  #
  # Callers use `ide_layout_apply(cx, pane)`; `ide_layout_pane(cx)` picks the
  # focused pane, or the window's first when nothing is focused (headless).
  # Names are prefixed so this can sit beside an inliner's own locals.
  ideLayout = ''
    local IDE_TOP_RATIO = 0.75
    local IDE_LEFT_RATIO = 0.68
    local IDE_AGENT_COMMAND = "omp"

    -- A TabTree leaf is {pane=...}; every other node is a split with [1] and [2], `split` naming its axis
    -- The leaf's parent IS the divider that resizes it; a "has children" match would pick a nested divider
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

    -- `split` is the TabTree value as passed here ("right"/"down"), NOT the "Row"/"Column" axis of `tern inspect`
    -- resize grows a pane TOWARD dir, i.e. toward its sibling, so widening across a divider means growing away
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

    -- Cell size is not exposed window-side (PaneInfo has no cell fields, BlockCx.cols/rows is host-only), so a
    -- 1-cell probe measures the axis; resize(pane, probe, -1) is its exact inverse
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

    -- The pane the layout applies to: the focused one, else the window's first
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

    -- Split down before right, else the tree comes out three-region; focus = false keeps the caller's pane focused
    local function ide_layout_apply(cx, pane)
      if pane == nil then
        return false
      end

      local south = cx.layout:split(pane, "down", nil, { focus = false })
      if south == nil then
        return false
      end
      ide_nudge(cx, pane, "down", IDE_TOP_RATIO)

      local tr = cx.layout:split(pane, "right", { command = IDE_AGENT_COMMAND }, { focus = false })
      if tr == nil then
        return false
      end
      ide_nudge(cx, pane, "right", IDE_LEFT_RATIO)

      local br = cx.layout:split(south, "right", nil, { focus = false })
      if br == nil then
        return false
      end

      cx.layout:focus(pane)
      return true
    end
  '';
}
