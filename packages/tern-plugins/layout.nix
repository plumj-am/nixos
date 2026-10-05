{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern loads a plugin from a directory holding plugin.toml plus the entry it
      # names, so both are written into one store path from strings, not loose files
      packages.tern-ide-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-ide-plugin.toml" {
            schema = 1;
            id = "ide";
            name = "tern-ide";
            version = "0.1.0";
            description = "IDE-like four-cell workspace layout with explicit split ratios.";

            window = "init.luau";
          };

          entry =
            pkgs.writers.writeText "tern-ide-init.luau" # luau
              ''
                --!nonstrict
                local TOP_RATIO = 0.75
                local LEFT_RATIO = 0.68
                local BOTTOM_RATIO = 0.5
                local AGENT_COMMAND = "omp"

                -- A TabTree leaf is {pane=...}; every other node is a split with [1] and [2], `split` naming its axis
                -- The leaf's parent IS the divider that resizes it; a "has children" match would pick a nested divider
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

                -- `split` is the TabTree value as passed here ("right"/"down"), NOT the "Row"/"Column" axis of `tern inspect`
                -- resize grows a pane TOWARD dir, i.e. toward its sibling, so widening across a divider means growing away
                local function grow_across(split, is_first)
                  if split == "right" then
                    return is_first and "right" or "left"
                  end
                  return is_first and "down" or "up"
                end

                local function share_of(found)
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
                    -- cx.session:focused() is nil in a headless session, so fall back to the window's first pane
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

                    -- Split down before right, else the tree comes out three-region; focus = false keeps the user's pane focused
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

                    local br = cx.layout:split(south, "right", nil, { focus = false })
                    if br == nil then
                      return
                    end

                    cx.layout:focus(pane)
                  end,
                })

                -- tern silently drops a plugin bind whose chord the keymap preset already owns, so pick an unused one
                tern.bind("ctrl+alt+shift+f9", "plugin.ide.layout")
              '';
        in
        pkgs.runCommand "tern-ide-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
        '';
    };
}
