{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # The tern-ide plugin, packaged so hjem can copy it into
      # ~/.config/tern/plugins/ide/. tern loads a plugin from a directory holding
      # plugin.toml plus the window entry it names, so both are written into one
      # store path from strings kept here, not as loose files.
      packages.tern-ide-plugin =
        let
          manifest = pkgs.writers.writeText "tern-ide-plugin.toml" ''
            schema = 1
            id = "ide"
            name = "tern-ide"
            version = "0.1.0"
            description = "IDE-like four-cell workspace layout with explicit split ratios."

            # Only window-level entry points, so `window` names the entry file
            # and there is no host entry.
            window = "init.luau"
          '';

          entry =
            pkgs.writers.writeText "tern-ide-init.luau" # luau
              ''
                --!nonstrict
                -- Build an IDE-like four-cell workspace layout in the focused tab,
                -- with the same ratios as herdr-ide.
                --
                --   +-----------------------+
                --   | 68x75        | 32x75  |
                --   |              |        |
                --   +-----------------------+
                --   | 50x25     | 50x25     |
                --   +-----------------------+
                --
                -- Two constraints:
                --
                --   * `cx.layout:tab(spec)` takes no tab argument. It always builds
                --     into the first tab and MERGES into whatever tree is there, so
                --     it cannot rebuild the tab the user is sitting in.
                --   * `cx.layout:resize` takes CELLS, not a ratio, and reports false
                --     when no divider moved.
                --
                -- So the tree is built with the split primitive, then each divider
                -- is measured and moved once. `cx.session:layout(tab)` exposes every
                -- split's ratio, which is the only window-side size signal there is
                -- (PaneInfo carries no cell size; BlockCx.cols/rows is host-only).
                -- Nothing is closed.

                local TOP_RATIO = 0.75
                local LEFT_RATIO = 0.68
                local BOTTOM_RATIO = 0.5
                local AGENT_COMMAND = "omp"

                -- The split node that directly contains `pane`, or nil at a leaf /
                -- off-tree. A TabTree leaf is {pane=...}; every other node is a
                -- split with [1] and [2], and `split` names its axis. The parent of
                -- the leaf IS the divider that resizes it, so this is the only node
                -- that matters. Matching on "has children" instead would pick a
                -- nested divider and overshoot.
                local function parent_of(node, pane)
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

                  return parent_of(left, pane) or parent_of(right, pane)
                end

                -- `split` here is TabTree's value as the caller passes it: "right"
                -- for a vertical divider, "down" for a horizontal one. That is NOT
                -- the `axis` field `tern inspect` prints ("Row"/"Column"), which is
                -- why this tests the split direction and not "Row".
                --
                -- resize grows a pane TOWARD dir, so on a divider that moves the
                -- pane toward the SIBLING. To widen `pane` across its own divider,
                -- grow away from that sibling: the first subtree grows right/down,
                -- the second left/up.
                local function grow_across(split, is_first)
                  if split == "right" then
                    return is_first and "right" or "left"
                  end
                  return is_first and "down" or "up"
                end

                -- Current share of `pane` on its divider. ratio is the FIRST
                -- subtree's share.
                local function share_of(found)
                  if found.first then
                    return found.node.ratio
                  end
                  if found.node.ratio == nil then
                    return nil
                  end
                  return 1 - found.node.ratio
                end

                -- Move one divider to `want` in a single resize.
                --
                -- The cell size is not exposed anywhere on the window side: PaneInfo
                -- has no cell fields and BlockCx.cols/rows is host-only. But resize
                -- moves whole cells, so one 1-cell probe measures the axis: if that
                -- moves the share by d, the axis is 1/d cells and `want` sits
                -- (want-here)/d cells away. Stepping one cell at a time cannot land
                -- on a fraction, which is why this probes and then jumps.
                --
                -- Direction is measured rather than assumed: the probe shows which
                -- way resize actually moves the share, and the correcting call uses
                -- that sign. `resize(pane, probe, -1)` is the exact inverse of the
                -- probe, so undoing it needs no sign reasoning.
                local function nudge(cx, pane, split, want)
                  local function measure()
                    local tab = cx.session:tab_of(pane)
                    if tab == nil then
                      return nil, nil
                    end

                    local tree = cx.session:layout(tab)
                    if tree == nil then
                      return nil, nil
                    end

                    local found = parent_of(tree.root, pane)
                    if found == nil or found.node.split ~= split then
                      return nil, nil
                    end

                    return share_of(found), found
                  end

                  local here = measure()
                  if here == nil or math.abs(here - want) < 0.005 then
                    return
                  end

                  local probe = grow_across(split, true)
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

                tern.command({
                  id = "layout",
                  title = "IDE layout (four cells)",
                  icon = "layout",
                  group = "tern-ide",
                  run = function(cx)
                    -- The user's pane. cx.session:focused() is nil in a headless
                    -- session, so fall back to the first pane of the window.
                    local pane = cx.session:focused()
                    if pane == nil then
                      for _, other in cx.session:panes() do
                        pane = other.pane
                        break
                      end
                    end
                    if pane == nil then
                      return
                    end

                    -- Order matters. Splitting down first gives the two rows;
                    -- splitting each row right then gives the four cells. Splitting
                    -- right first instead leaves the last pane spanning the full
                    -- height, a three-region tree.
                    --
                    -- focus = false keeps the user's pane focused throughout.
                    local south = cx.layout:split(pane, "down", nil, { focus = false })
                    if south == nil then
                      return
                    end
                    nudge(cx, pane, "down", TOP_RATIO)

                    local tr = cx.layout:split(pane, "right", { command = AGENT_COMMAND }, { focus = false })
                    if tr == nil then
                      return
                    end
                    nudge(cx, pane, "right", LEFT_RATIO)

                    -- 0.50 is what an even split already gives, so no nudge.
                    local br = cx.layout:split(south, "right", nil, { focus = false })
                    if br == nil then
                      return
                    end

                    cx.layout:focus(pane)
                  end,
                })

                -- A chord the tmux preset does not use. ctrl+g>l was tried first
                -- and tern dropped it: the keymap preset already owns that chord,
                -- and a plugin bind that collides is left out. Not reachable from
                -- `tern send`, which writes to a pane's pty rather than the window
                -- keymap.
                tern.bind("ctrl+alt+shift+f9", "plugin.ide.layout")
              '';
        in
        pkgs.runCommand "tern-ide-plugin" { } ''
          mkdir -p "$out"
          ln -s ${manifest} "$out/plugin.toml"
          ln -s ${entry} "$out/init.luau"
        '';
    };
}
