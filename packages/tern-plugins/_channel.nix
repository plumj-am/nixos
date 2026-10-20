# Shared Luau for the tern-plugins packages. outputs.nix skips any path holding
# "/_", so this file is not pulled into the flake's module tree.
{
  # A host half and a window half of one plugin cannot call each other: the
  # API split is one-way, and the only shared state is the plugin's data
  # directory and its kv store (docs: concepts/architecture.md, "talk to
  # each other only through what Tern carries between them").
  #
  # This is the channel over that shared state: the host half owns the work
  # (2 s budget, its own worker thread), the window half owns the reading
  # and the chrome (4 ms and 50 ms budgets, the UI thread).
  #
  # The window half asks with a request file; the host half answers with a
  # reply file. Both live under tern.plugin.data, which both halves see at
  # the same absolute path. A reply is written whole, then the request is
  # removed, so a reply file that exists is always a complete reply.
  #
  # Callers use `channel_host(...)` and `channel_window(...)`; the locals are
  # prefixed so inlined copies cannot clash with a caller's own names.
  channel = # luau
    ''
      -- Shared layout: tern.plugin.data is the same absolute path in both
      -- halves, so the two directories below are the same directories.
      local CHANNEL_DIR = "channel"
      local REQ_DIR = CHANNEL_DIR .. "/req"
      local REPLY_DIR = CHANNEL_DIR .. "/reply"

      local function channel_path(dir: string, name: string): string
        return tern.plugin.data .. "/" .. dir .. "/" .. name
      end

      -- The host half: answer requests, one file per request.
      --
      -- `answer(name, payload)` writes the reply as JSON. The request is
      -- removed only after the reply is in place, so a reply file that
      -- exists is a whole reply and never half of one.
      local function channel_host(handle)
        local dirs_ready = false

        local function ensure_dirs()
          if dirs_ready then
            return
          end
          -- Both halves may create them: mkdir on an existing directory
          -- fails, so each call is guarded.
          pcall(tern.fs.mkdir, tern.plugin.data .. "/" .. CHANNEL_DIR)
          pcall(tern.fs.mkdir, tern.plugin.data .. "/" .. REQ_DIR)
          pcall(tern.fs.mkdir, tern.plugin.data .. "/" .. REPLY_DIR)
          dirs_ready = true
        end

        -- Answer one request.
        --
        -- One request per pass: a burst of them, each with its own
        -- process or file work, would share the host's 2 s budget, and a
        -- pass that runs over its budget disables the hook until the
        -- next reload. The rest wait in the request directory for the
        -- next pass.
        local function serve_one()
          ensure_dirs()
          local ok, names = pcall(tern.fs.list, tern.plugin.data .. "/" .. REQ_DIR)
          if not ok or #names == 0 then
            return false
          end

          local name = names[1]
          local path = channel_path(REQ_DIR, name)
          local read_ok, text = pcall(tern.fs.read, path)
          if not read_ok or type(text) ~= "string" then
            -- A partial write: leave it and try again next pass.
            return false
          end

          local decoded_ok, request = pcall(tern.json.decode, text)
          if not decoded_ok or type(request) ~= "table" then
            pcall(tern.log.warn, "tern channel: unreadable request " .. name)
            return false
          end

          -- The reply goes first: the request is the handshake, and
          -- removing it before the reply lands would lose the answer.
          --
          -- The handler gets the request's name, so it can answer
          -- later: work that takes a process round trip cannot
          -- return its answer in this call.
          local payload = handle(request, name)
          if payload ~= nil then
            local encoded_ok, encoded = pcall(tern.json.encode, payload)
            if encoded_ok then
              pcall(tern.fs.write, channel_path(REPLY_DIR, name), encoded)
            end
          end
          pcall(tern.fs.remove, path)
          return true
        end

        -- The poll runs on the host worker, which has the 2 s budget and
        -- none of the UI thread's constraints.
        --
        -- The timer is armed first: a pass that runs over its budget
        -- disables the hook, and a disabled hook is never called again.
        -- Arming first means a slow pass costs one request, not the
        -- whole channel.
        --
        -- The handle is not kept: the timer re-arms itself, and the
        -- host half has no way to stop it.
        local function tick()
          tern.timer(200, tick)
          serve_one()
        end

        ensure_dirs()
        tern.timer(200, tick)

        return {
          -- Answer a request the window half is waiting for, with a name
          -- the window half asked for.
          answer = function(name, payload)
            local encoded_ok, encoded = pcall(tern.json.encode, payload)
            if not encoded_ok then
              return false
            end
            local write_ok = pcall(tern.fs.write, channel_path(REPLY_DIR, name), encoded)
            return write_ok
          end,
          -- Publish a value the window half polls for: the newest one wins,
          -- so a slow window misses updates but never shows a wrong one.
          publish = function(key, value)
            local encoded_ok, encoded = pcall(tern.json.encode, value)
            if not encoded_ok then
              return false
            end
            pcall(tern.fs.mkdir, tern.plugin.data .. "/" .. CHANNEL_DIR)
            local write_ok = pcall(tern.fs.write, channel_path(CHANNEL_DIR, key), encoded)
            return write_ok
          end,
        }
      end

      -- The window half: ask the host half, and read what it published.
      --
      -- Nothing here waits: a window half call has 50 ms, and a request
      -- may take the host a second. The answer arrives as a file, and
      -- `poll` hands it to the callback that asked for it.
      local function channel_window()
        local dirs_ready = false
        local sequence = 0
        local waiting = {}

        -- The requests that are not written yet. `request_later` puts
        -- them here, and the poll writes them in its own tick.
        local pending = {}
        local pending_count = 0

        local function ensure_dirs()
          if dirs_ready then
            return
          end
          pcall(tern.fs.mkdir, tern.plugin.data .. "/" .. CHANNEL_DIR)
          pcall(tern.fs.mkdir, tern.plugin.data .. "/" .. REQ_DIR)
          pcall(tern.fs.mkdir, tern.plugin.data .. "/" .. REPLY_DIR)
          dirs_ready = true
        end

        -- The directories are made when the window half loads, not when
        -- the first request goes out. A request is written from a hook
        -- with a 50 ms budget, and three mkdir calls on a cold data
        -- directory cost the UI thread the time they take.
        ensure_dirs()

        -- A name that is unique per request, so a reply can never be
        -- mistaken for an older one.
        local function next_name(prefix: string): string
          sequence += 1
          return string.format("%s-%d-%d", prefix, os.time(), sequence)
        end

        -- Read and remove the reply for a request, if the host has
        -- answered it yet. Returns nil while the answer is in flight.
        local function read_reply(name: string?): { [string]: any }?
          if name == nil then
            return nil
          end
          local path = channel_path(REPLY_DIR, name)
          local ok, text = pcall(tern.fs.read, path)
          if not ok or type(text) ~= "string" then
            return nil
          end
          pcall(tern.fs.remove, path)
          local decoded_ok, payload = pcall(tern.json.decode, text)
          if not decoded_ok then
            return nil
          end
          return payload
        end

        -- Send a request. `name` comes back so the caller can match the
        -- reply it wants.
        local function ask(prefix: string?, request: { [string]: any }): string?
          ensure_dirs()
          local name = next_name(prefix or "req")
          local encoded_ok, encoded = pcall(tern.json.encode, request)
          if not encoded_ok then
            return nil
          end
          local write_ok = pcall(tern.fs.write, channel_path(REQ_DIR, name), encoded)
          if not write_ok then
            return nil
          end
          return name
        end

        -- The local is declared before the table, not in front of it: a
        -- local's scope starts after its own statement, so a table
        -- constructor that mentions the name would read a global.
        local channel
        channel = {
          ask = ask,

          -- Send a request and get the answer through a callback.
          --
          -- The reply is picked up by `poll`, so the caller must run it:
          -- a window half that only asks and never polls waits forever.
          -- The callback runs on the poll's own timer tick, which is a
          -- 50 ms hook like any other.
          request = function(
            prefix: string,
            request: { [string]: any },
            on_reply: (payload: { [string]: any }?, reply_cx: WindowCx) -> ()
          ): string?
            local name = ask(prefix, request)
            if name == nil then
              return nil
            end
            waiting[name] = on_reply
            return name
          end,

          -- Send a request without writing the file now.
          --
          -- Writing the request is a disk write, and a command handler
          -- has 50 ms for everything it does. So the write happens in
          -- the next poll tick, and the handler returns at once.
          --
          -- The answer arrives the same way, so the whole round trip
          -- costs the hook that made it one table insert.
          request_later = function(
            prefix: string,
            request: { [string]: any },
            on_reply: (payload: { [string]: any }?, reply_cx: WindowCx) -> ()
          )
            pending_count = pending_count + 1
            pending[pending_count] = { prefix = prefix, request = request, on_reply = on_reply }
            return true
          end,

          -- Drain the replies that arrived, calling each callback.
          --
          -- One reply per tick: a burst of answers would otherwise
          -- bill every callback to the same hook pass, and the last one
          -- would trip the 50 ms budget.
          --
          -- The callback gets a fresh cx of its own, in a pass of its
          -- own, so it can toast or act on the window. A cx is only
          -- valid during the call that received it, so a stored one
          -- would raise.
          poll = function(_cx: WindowCx?): number
            -- Write the requests that were deferred. One per tick, so a
            -- burst of them does not fill one hook pass.
            if pending_count > 0 then
              local item = pending[1]
              for index = 1, pending_count - 1 do
                pending[index] = pending[index + 1]
              end
              pending[pending_count] = nil
              pending_count = pending_count - 1
              if item ~= nil then
                local name = ask(item.prefix, item.request)
                if name ~= nil then
                  waiting[name] = item.on_reply
                end
              end
              -- The answer comes in a later tick, so this pass is done.
              return 1
            end

            -- One answer per tick: a burst of answers would otherwise
            -- bill every callback to the same hook pass, and the last one
            -- would trip the 50 ms budget.
            for name, on_reply in pairs(waiting) do
              local payload = read_reply(name)
              if payload ~= nil then
                waiting[name] = nil
                -- The handler runs in its own pass.
                --
                -- The pass that reads the reply has already spent part
                -- of its 50 ms on the file read, and a handler that
                -- draws (a picker, a toast, a chrome refresh) spends
                -- the rest of it on the draw. The draw runs the chrome
                -- formatters, and a formatter's 4 ms budget is what is
                -- left of the deadline of the call that drew, so a
                -- formatter that ran under a spent deadline was
                -- disabled for the rest of the window's life.
                --
                -- `sleep(0)` re-arms the chain as its own `await` hook,
                -- so the handler gets a fresh 50 ms and a fresh cx.
                tern.sleep(0):next(function(_result, _err, live)
                  if live == nil then
                    return
                  end
                  -- The handler returns nothing, so a pcall around it
                  -- returns one value: the ok flag. The handler logs
                  -- its own failure.
                  local ok = pcall(on_reply, payload, live)
                  if not ok then
                    tern.log.warn("tern channel: reply handler failed")
                  end
                end)
                -- One answer per tick, so the rest wait for the next.
                return 1
              end
            end
            return 0
          end,

          -- Forget a request that will never be answered.
          forget = function(name: string?)
            if name ~= nil then
              waiting[name] = nil
            end
          end,

          reply = read_reply,

          -- Read a published value. The newest one wins: a value that
          -- changed while the window was busy is simply the new one.
          published = function(key: string): { [string]: any }?
            local ok, text = pcall(tern.fs.read, channel_path(CHANNEL_DIR, key))
            if not ok or type(text) ~= "string" then
              return nil
            end
            local decoded_ok, payload = pcall(tern.json.decode, text)
            if not decoded_ok then
              return nil
            end
            return payload
          end,

          -- A timer that keeps the channel moving.
          --
          -- The window half must run this, or a request never gets its
          -- answer and the split silently stops updating. The poll runs
          -- on its own tick, so a slow answer never blocks the window.
          start = function(interval_ms: number?, on_poll: ((cx: WindowCx?) -> ())?)
            local timer = nil
            local function tick(cx: WindowCx?)
              -- The timer is armed first: a pass that runs over its
              -- budget disables the hook, and a disabled hook is never
              -- called again.
              timer = tern.timer(interval_ms or 200, tick)
              local ok = pcall(channel.poll, cx)
              if not ok then
                tern.log.warn("tern channel: poll failed")
              end
              if on_poll ~= nil then
                local called_ok = pcall(on_poll, cx)
                if not called_ok then
                  tern.log.warn("tern channel: poll callback failed")
                end
              end
            end
            timer = tern.timer(interval_ms or 200, tick)
            return timer
          end,
        }

        return channel
      end
    '';
}
