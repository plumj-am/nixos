{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-lenses plugin: command lenses for commands Tern has no built-in
      # family for. Each lens parses what it can and returns nil from `view`
      # when the output does not fit, which leaves the raw output in place.
      # A lens only runs where the shell reports its command line (OSC 133):
      # bash, zsh, fish and xonsh do; nushell does not.
      packages.tern-lenses-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-lenses-plugin.toml" {
            schema = 1;
            id = "lenses";
            name = "Tern Lenses";
            version = "0.1.0";
            description = "Lenses for Tern.";
            icon = "sparkle";

            host = "host.luau";

            lenses = [
              {
                id = "nix";
                match = [
                  "nix build"
                  "nix build *"
                  "nix log *"
                  "nix flake check"
                  "nix flake check *"
                  "nixos-rebuild"
                  "nixos-rebuild *"
                ];
              }
              {
                id = "lsblk";
                match = [
                  "lsblk"
                  "lsblk *"
                ];
              }
              {
                id = "gpu";
                match = [
                  "nvidia-smi"
                  "nvidia-smi *"
                ];
              }
            ];
          };

          host =
            pkgs.writers.writeText "tern-lenses-host.luau" # luau
              ''
                --!nonstrict
                -- One lens per command family Tern leaves raw. `line` only
                -- collects, `view` builds the node tree, and state is always a
                -- function of the run and the lines, so a rehydrated block
                -- (after a reload) rebuilds the same view.

                local ui = tern.ui

                local NIX_ROWS = 100
                local BLK_ROWS = 200

                local function plural(n, one, many)
                  if n == 1 then
                    return one
                  end
                  return many
                end

                local function human(bytes)
                  local units = { "B", "KiB", "MiB", "GiB", "TiB" }
                  local value = bytes
                  local unit = 1
                  while value >= 1024 and unit < #units do
                    value = value / 1024
                    unit = unit + 1
                  end
                  if unit == 1 then
                    return string.format("%d%s", value, units[unit])
                  end
                  return string.format("%.1f%s", value, units[unit])
                end

                local function mib(value)
                  if value >= 1024 then
                    return string.format("%.1fGiB", value / 1024)
                  end
                  return string.format("%dMiB", value)
                end

                local SIZE_UNITS = { K = 1024, M = 1024 * 1024, G = 1024 * 1024 * 1024, T = 1024 * 1024 * 1024 * 1024 }

                -- tern.parse.size knows "1.2GB" and "4.0K"; lsblk prints "953.9G",
                -- so fall back to a local read of the plain-unit form.
                local function size_bytes(text)
                  local bytes = tern.parse.size(text)
                  if bytes ~= nil then
                    return bytes
                  end
                  local value, unit = string.match(text, "^([%d%.]+)%s*([KMGTPE]?)i?[Bb]?$")
                  if value == nil then
                    return nil
                  end
                  return tonumber(value) * (SIZE_UNITS[unit] or 1)
                end

                -- nix: `error:` and `warning:` lines become diagnostic cards.
                local nix = {
                  open = function(run, _cx)
                    return { cwd = run.cwd, command = run.line, items = {}, errors = 0, warnings = 0, hidden = 0 }
                  end,

                  line = function(state, l)
                    local text = l.text
                    if text == "" then
                      return
                    end
                    local level, rest = string.match(text, "^%s*(error):%s*(.*)$")
                    if level == nil then
                      level, rest = string.match(text, "^%s*(warning):%s*(.*)$")
                    end
                    if level == nil then
                      -- Nix wraps a diagnostic over indented lines.
                      local last = state.items[#state.items]
                      if last ~= nil and string.match(text, "^%s") ~= nil and #last.notes < 10 then
                        table.insert(last.notes, (string.gsub(text, "^%s+", "")))
                        if last.path == nil then
                          local path, number, col = string.match(text, "([%w%._%-/]+%.nix):(%d+):(%d+)")
                          if path ~= nil then
                            last.path, last.line, last.col = path, tonumber(number), tonumber(col)
                          end
                        end
                      end
                      return
                    end
                    if level == "error" then
                      state.errors = state.errors + 1
                    else
                      state.warnings = state.warnings + 1
                    end
                    if #state.items >= NIX_ROWS then
                      state.hidden = state.hidden + 1
                      return
                    end
                    local path, number, col = string.match(rest, "([%w%._%-/]+%.nix):(%d+):(%d+)")
                    table.insert(state.items, {
                      level = level,
                      message = rest,
                      path = path,
                      line = number and tonumber(number) or nil,
                      col = col and tonumber(col) or nil,
                      notes = {},
                    })
                  end,

                  finish = function(_state, _status) end,

                  view = function(state)
                    if state.errors + state.warnings == 0 then
                      return nil
                    end
                    local head = {}
                    if state.errors > 0 then
                      table.insert(head, ui.badge(state.errors .. " " .. plural(state.errors, "error", "errors"), "error"))
                    end
                    if state.warnings > 0 then
                      table.insert(head, ui.badge(state.warnings .. " " .. plural(state.warnings, "warning", "warnings"), "warn"))
                    end
                    table.insert(head, ui.text({ ui.span(state.command, "muted") }))
                    local body = { ui.row(head) }
                    for _, item in state.items do
                      table.insert(body, ui.diagnostic({
                        severity = item.level,
                        message = item.message,
                        path = item.path,
                        line = item.line,
                        col = item.col,
                        notes = #item.notes > 0 and item.notes or nil,
                      }, state.cwd))
                    end
                    if state.hidden > 0 then
                      table.insert(body, ui.overflow(state.hidden))
                    end
                    return ui.col(body)
                  end,
                }

                -- lsblk: the default columns are NAME MAJ:MIN RM SIZE RO TYPE
                -- MOUNTPOINTS; the name keeps lsblk's own tree glyphs.
                local lsblk = {
                  open = function(run, _cx)
                    return { cwd = run.cwd, rows = {}, disks = 0, total = 0, hidden = 0 }
                  end,

                  line = function(state, l)
                    local text = l.text
                    if text == "" or string.match(text, "^NAME") ~= nil then
                      return
                    end
                    local name, _majmin, rest = string.match(text, "^(.-)%s+(%d+:%d+)%s+(.*)$")
                    if name == nil then
                      -- lsblk wraps a row's later mountpoints onto a glyph-only line.
                      local wrapped = (string.gsub((string.gsub(text, "^[│├└─%s]+", "")), "%s+$", ""))
                      local last = state.rows[#state.rows]
                      if wrapped ~= "" and last ~= nil and string.find(wrapped, "^%S+$") ~= nil then
                        last.mounts = last.mounts .. " " .. wrapped
                      else
                        state.hidden = state.hidden + 1
                      end
                      return
                    end
                    local rm, size, ro, kind, tail = string.match(rest, "^(%d+)%s+(%S+)%s+(%d+)%s+(%S+)%s*(.*)$")
                    if size == nil then
                      state.hidden = state.hidden + 1
                      return
                    end
                    local bytes = size_bytes(size) or 0
                    if kind == "disk" then
                      state.disks = state.disks + 1
                      state.total = state.total + bytes
                    end
                    if #state.rows >= BLK_ROWS then
                      state.hidden = state.hidden + 1
                      return
                    end
                    table.insert(state.rows, {
                      name = name,
                      size = size,
                      bytes = bytes,
                      kind = kind,
                      ro = ro == "1",
                      rm = rm == "1",
                      mounts = tail,
                    })
                  end,

                  finish = function(_state, _status) end,

                  view = function(state)
                    if #state.rows == 0 then
                      return nil
                    end
                    local largest = 1
                    for _, row in state.rows do
                      if row.bytes > largest then
                        largest = row.bytes
                      end
                    end
                    local cells = {}
                    for i, row in state.rows do
                      local mounts = {}
                      for word in string.gmatch(row.mounts, "%S+") do
                        table.insert(mounts, ui.path(word, state.cwd))
                        table.insert(mounts, ui.span(" "))
                      end
                      if #mounts == 0 then
                        table.insert(mounts, ui.span("-", "muted"))
                      end
                      local flags = {}
                      if row.ro then
                        table.insert(flags, ui.span("ro", "muted"))
                      end
                      if row.rm then
                        table.insert(flags, ui.span("rm", "warn"))
                      end
                      cells[i] = {
                        { ui.span(row.name) },
                        { ui.span(row.size, "num") },
                        ui.meter_cell(row.bytes / largest),
                        { ui.span(row.kind, "muted") },
                        flags,
                        mounts,
                      }
                    end
                    local body = {
                      ui.row({
                        ui.badge(state.disks .. " " .. plural(state.disks, "disk", "disks"), "accent"),
                        ui.badge(human(state.total) .. " total", "muted"),
                        ui.badge(#state.rows .. " " .. plural(#state.rows, "row", "rows"), "muted"),
                      }),
                      ui.table({
                        { id = "name", head = "Name", grow = 1, truncate = "middle" },
                        { id = "size", head = "Size", align = "end" },
                        { id = "share", head = "Share", priority = -1 },
                        { id = "kind", head = "Type" },
                        { id = "flags", head = "Flags" },
                        { id = "mounts", head = "Mountpoints" },
                      }, cells),
                    }
                    if state.hidden > 0 then
                      table.insert(body, ui.overflow(state.hidden))
                    end
                    return ui.col(body)
                  end,
                }

                -- nvidia-smi: one card per GPU, read from the metrics row that
                -- follows each GPU's name row.
                local gpu = {
                  open = function(run, _cx)
                    return { cwd = run.cwd, order = {}, by_index = {}, current = nil }
                  end,

                  line = function(state, l)
                    local text = l.text
                    local index, name = string.match(text, "^|%s*(%d+)%s+(%a[%w%s%-%._%(%)]*%w)%s+%a+%s*|")
                    -- Only a GPU's own row carries a bus id and no memory column;
                    -- the process table below has the same shape otherwise.
                    if index ~= nil and string.match(text, "%x+:%x+:%x+%.%d") ~= nil and string.find(text, "MiB") == nil then
                      local entry = state.by_index[index]
                      if entry == nil then
                        entry = { index = index, name = name }
                        state.by_index[index] = entry
                        table.insert(state.order, index)
                      end
                      state.current = entry
                      return
                    end
                    local fan, temp = string.match(text, "^|%s*(%d+)%%%s+(%d+)%s*C")
                    if fan == nil then
                      return
                    end
                    local entry = state.current
                    if entry == nil then
                      return
                    end
                    local power, cap = string.match(text, "([%d%.]+)W%s*/%s*([%d%.]+)W")
                    local used, total = string.match(text, "(%d+)MiB%s*/%s*(%d+)MiB")
                    local util = string.match(text, "|%s*(%d+)%%%s*%a")
                    entry.fan = tonumber(fan)
                    entry.temp = tonumber(temp)
                    entry.power = power
                    entry.cap = cap
                    entry.used = used and tonumber(used) or nil
                    entry.total = total and tonumber(total) or nil
                    entry.util = util and tonumber(util) or nil
                  end,

                  finish = function(_state, _status) end,

                  view = function(state)
                    if #state.order == 0 then
                      return nil
                    end
                    local body = {}
                    for _, index in state.order do
                      local entry = state.by_index[index]
                      local rows = {}
                      if entry.util ~= nil then
                        table.insert(rows, ui.meter(entry.util / 100, { ui.span("GPU " .. entry.util .. "%") }))
                      end
                      if entry.used ~= nil and entry.total ~= nil and entry.total > 0 then
                        table.insert(rows, ui.meter(entry.used / entry.total, {
                          ui.span("VRAM " .. mib(entry.used) .. " / " .. mib(entry.total)),
                        }))
                      end
                      if entry.temp ~= nil then
                        table.insert(rows, ui.meter(entry.temp / 100, { ui.span("Temp " .. entry.temp .. "C") }))
                      end
                      local facts = {}
                      if entry.fan ~= nil then
                        table.insert(facts, { ui.span("fan", "muted"), ui.span(entry.fan .. "%") })
                      end
                      if entry.power ~= nil and entry.cap ~= nil then
                        table.insert(facts, { ui.span("power", "muted"), ui.span(entry.power .. " / " .. entry.cap .. "W") })
                      end
                      if #facts > 0 then
                        table.insert(rows, ui.kv(facts))
                      end
                      table.insert(body, ui.card({ ui.span("GPU " .. entry.index), ui.span(" " .. entry.name, "muted") }, rows))
                    end
                    return ui.col(body)
                  end,
                }

                tern.lens.define("nix", nix)
                tern.lens.define("lsblk", lsblk)
                tern.lens.define("gpu", gpu)
              '';
        in
        pkgs.runCommand "tern-lenses-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${host} "$out/host.luau"
        '';
    };
}
