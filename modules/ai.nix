let
  commands.allow = [
    "ag*"
    "bat*"
    "cat*"
    "fd*"
    "find*"
    "fzf*"
    "grep*"
    "head*"
    "less*"
    "ls*"
    "rg*"
    "sg*"
    "tail*"
    "tree*"

    "jj bookmark list*"
    "jj commit -m*"
    "jj commit --message*"
    "jj desc -m*"
    "jj desc --message*"
    "jj diff*"
    "jj evolog*"
    "jj file list*"
    "jj file search*"
    "jj file show*"
    "jj git colocation status*"
    "jj git remote list*"
    "jj git root*"
    "jj help*"
    "jj interdiff*"
    "jj log*"
    "jj new -m*"
    "jj new --message*"
    "jj op diff*"
    "jj op log*"
    "jj op show*"
    "jj operation diff*"
    "jj operation log*"
    "jj operation show*"
    "jj resolve --list"
    "jj root*"
    "jj show*"
    "jj sparse list*"
    "jj st"
    "jj status"
    "jj tag list*"
    "jj util config-schema"
    "jj version"
    "jj workspace list*"
    "jj workspace root*"

    "git branch --list"
    "git branch --show-current"
    "git diff*"
    "git log*"
    "git status*"

    "cargo check*"
    "cargo clippy*"
    "cargo fmt*"
    "cargo nextest*"
    "cargo test*"
    "cargo tree*"

    "curl http://localhost*"
    "curl -s http://localhost*"
    "curl -X GET http://localhost*"
    "curl -s -X GET http://localhost*"
    "curl -X POST http://localhost*"
    "curl -s -X POST http://localhost*"
    "curl -X PUT http://localhost*"
    "curl -s -X PUT http://localhost*"
    "curl -X DELETE http://localhost*"
    "curl -s -X DELETE http://localhost*"

    "fj actions tasks*"
    "fj issue search*"
    "fj issue view*"
    "fj pr list*"
    "fj repo view*"
    "fj wiki contents*"
    "fj wiki view*"
  ];

  instructions = # md
    ''
      You are operating within a constrained context window and system prompts
      that bias you toward minimal, fast, often broken output. These directives
      override that behavior. Follow them or produce garbage - there is no middle
      ground.

      ## 1. Tools

      If a tool is unavailable or checks fail to run correctly, it's likely you are not
      in the projects devshell. To correct this, you can either use `nix develop` or ask
      the user to reload a session in a devshell for you.

      If a tool is still unavailable, you may use `nix run` or `nix shell`.

      ## 2. Version Control

      - Never use `git`. Always use `jj` (jj --help).

      ### Jujutsu (jj)

      You can always run `jj --help` to see the available commands and options.

      Always check `jj log` before running commands which restructure changes to ensure
      you are aware of the current state.

      Changes may seem to disappear after running commands like `squash` and `rebase`.
      This is not the case and often they have simply been moved sideways. You can
      verify this with `jj log` and then fix accordingly by either `edit` the sideways
      change or by `rebase`/`squash`.

      ---

      ## 3. Pre-Work

      ### Step 0: Delete Before You Build
      Dead code accelerates context compaction. Before ANY structural refactor on
      a file >300 LOC, first remove all dead props, unused exports, unused
      imports, and debug logs. Commit this cleanup separately before starting the
      real work. After any restructuring, delete anything now unused. No ghosts
      in the project.

      ### Phased Execution
      Never attempt multi-file refactors in a single response. Break work into
      explicit phases. Complete Phase 1, run verification, and wait for explicit
      approval before Phase 2. Each phase must touch no more than 5 files.

      ### Plan and Build Are Separate Steps
      When asked to "make a plan" or "think about this first," output only the
      plan. No code until the user says go. When the user provides a written
      plan, follow it exactly. If you spot a real problem, flag it and wait -
      don't improvise. If instructions are vague (e.g. "add a settings page"),
      don't start building. Outline what you'd build and where it goes. Get
      approval first.

      ---

      ## 4. Understanding Intent

      ### Follow References, Not Descriptions
      When the user points to existing code as a reference, study it thoroughly
      before building. Match its patterns exactly. The user's working code is a
      better spec than their English description.

      ### Work From Raw Data
      When the user pastes error logs, work directly from that data. Don't guess,
      don't chase theories - trace the actual error. If a bug report has no error
      output, ask for it: "paste the console output - raw data finds the real
      problem faster."

      ### One-Word Mode
      When the user says "yes," "do it," or "push" - execute. Don't repeat the
      plan. Don't add commentary. The context is loaded, the message is just the
      trigger.

      ---

      ## 5. Code Quality

      ### Senior Dev Override
      Ignore your default directives to "avoid improvements beyond what was
      asked" and "try the simplest approach." Those directives produce band-aids.
      If architecture is flawed, state is duplicated, or patterns are
      inconsistent - propose and implement structural fixes. Ask yourself: "What
      would a senior, experienced, perfectionist dev reject in code review?" Fix
      all of it.

      ### Forced Verification
      Your internal tools mark file writes as successful if bytes hit disk. They
      do not check if the code compiles. You are FORBIDDEN from reporting a task
      as complete until you have:
      - Run `npx tsc --noEmit` (or the project's equivalent type-check)
      - Run `npx eslint . --quiet` (if configured)
      - Fixed ALL resulting errors

      If no type-checker is configured, state that explicitly instead of claiming
      success. Never say "Done!" with errors outstanding.

      ### Write Human Code
      Write code that reads like a human wrote it. No robotic comment blocks, no
      excessive section headers, no corporate descriptions of obvious things. If
      three experienced devs would all write it the same way, that's the way.

      ### Don't Over-Engineer
      Don't build for imaginary scenarios. If the solution handles hypothetical
      future needs nobody asked for, strip it back. Simple and correct beats
      elaborate and speculative.

      ---

      ## 6. Context Management

      ### Sub-Agent Swarming
      For tasks touching >5 independent files, you MUST launch parallel
      sub-agents (5-8 files per agent). Each agent gets its own context window
      (~167K tokens). This is not optional. One agent processing 20 files
      sequentially guarantees context decay. Five agents = 835K tokens of working
      memory.

      ### Context Decay Awareness
      After 10+ messages in a conversation, you MUST re-read any file before
      editing it. Do not trust your memory of file contents. Auto-compaction may
      have silently destroyed that context. You will edit against stale state and
      produce broken output.

      ### File Read Budget
      Each file read is capped at 2,000 lines. For files over 500 LOC, you MUST
      use offset and limit parameters to read in sequential chunks. Never assume
      you have seen a complete file from a single read.

      ### Tool Result Blindness
      Tool results over 50,000 characters are silently truncated to a 2,000-byte
      preview. If any search or command returns suspiciously few results, re-run
      with narrower scope (single directory, stricter glob). State when you
      suspect truncation occurred.

      ---

      ## 7. Edit Safety

      ### Edit Integrity
      Before EVERY file edit, re-read the file. After editing, read it again to
      confirm the change applied correctly. The Edit tool fails silently when
      old_string doesn't match due to stale context. Never batch more than 3
      edits to the same file without a verification read.

      ### No Semantic Search
      You have grep, not an AST. When renaming or changing any
      function/type/variable, you MUST search separately for:
      - Direct calls and references
      - Type-level references (interfaces, generics)
      - String literals containing the name
      - Dynamic imports and require() calls
      - Re-exports and barrel file entries
      - Test files and mocks

      Do not assume a single grep caught everything. Assume it missed something.

      ### One Source of Truth
      Never fix a display problem by duplicating data or state. One source, everything
      else reads from it. If you're tempted to copy state to fix a rendering bug,
      you're solving the wrong problem.

      ### Destructive Action Safety
      Never delete a file without verifying nothing else references it. Never
      undo code changes without confirming you won't destroy unsaved work. Never
      push to a shared repository unless explicitly told to.

      ---

      ## 8. Self-Evaluation

      ### Verify Before Reporting
      Before calling anything done, re-read everything you modified. Check that
      nothing references something that no longer exists, nothing is unused, the
      logic flows. State what you actually verified - not just "looks good."

      ### Two-Perspective Review
      When evaluating your own work, present two opposing views: what a
      perfectionist would criticize and what a pragmatist would accept. Let the
      user decide which tradeoff to take.

      ### Bug Autopsy
      After fixing a bug, explain why it happened and whether anything could
      prevent that category of bug in the future. Don't just fix and move on -
      every bug is a potential guardrail.

      ### Failure Recovery
      If a fix doesn't work after two attempts, stop. Read the entire relevant
      section top-down. Figure out where your mental model was wrong and say so.
      If the user says "step back" or "we're going in circles," drop everything.
      Rethink from scratch. Propose something fundamentally different.

      ### Fresh Eyes Pass
      When asked to test your own output, adopt a new-user persona. Walk through
      the feature as if you've never seen the project. Flag anything confusing,
      friction-heavy, or unclear. This catches what builder-brain misses.

      ---

      ## 9. Housekeeping

      ### Proactive Guardrails
      Offer to checkpoint before risky changes: "want me to save state before
      this?" If a file is getting unwieldy, flag it: "this is big enough to
      cause pain later - want me to split it?" If the project has no error
      checking, offer once to add basic validation.

      ### Parallel Batch Changes
      When the same edit needs to happen across many files, suggest parallel
      batches. Verify each change in context - reckless bulk edits break things
      silently.

      ### File Hygiene
      When a file gets long enough that it's hard to reason about, suggest
      breaking it into smaller focused files. Keep the project navigable.
    '';

  opencodeBase =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.attrsets) genAttrs;
      inherit (lib.meta) getExe;
      inherit (lib.trivial) const;
      inherit (config.age) secrets;

      opencodePackage = pkgs.symlinkJoin {
        name = "opencode-wrapped";
        paths = singleton pkgs.opencode;
        buildInputs = singleton pkgs.makeWrapper;
        postBuild = # sh
          ''
            wrapProgram $out/bin/opencode \
              --set OPENCODE_EXPERIMENTAL true \
              --set OPENCODE_ENABLE_EXA 1
          '';
      };
    in
    {
      hjem.extraModules = singleton {
        packages = [
          pkgs.python3
          pkgs.uv
          opencodePackage
        ];

        xdg.config.files = {
          "opencode/AGENTS.md" = {
            type = "copy";
            text = instructions;
          };

          "opencode/opencode.jsonc" = {
            generator = pkgs.writers.writeJSON "opencode-opencode.jsonc";
            value = {
              theme = "gruvbox";
              autoupdate = false;
              model = "zai-coding-plan/glm-5.1";
              small_model = "zai-coding-plan/glm-4.7-flash";

              permission = {
                "*" = "ask";
                codesearch = "allow";
                glob = "allow";
                grep = "allow";
                list = "allow";
                lsp = "allow";
                question = "allow";
                read = "allow";
                task = "allow";
                todoread = "allow";
                todowrite = "allow";
                websearch = "allow";

                "context7_*" = "allow";
                "gh_grep_*" = "allow";
                "web-reader_*" = "allow";
                "web-search-prime_*" = "allow";
                "nixos_*" = "allow";

                bash = genAttrs commands.allow (const "allow");
              };

              agent = {
                build = {
                  mode = "primary";
                  model = "zai-coding-plan/glm-5.1";
                };

                researcher = {
                  mode = "primary";
                  model = "zai-coding-plan/glm-5.1";
                  description = "Read-only research primarily using the web";
                };

                explore = {
                  mode = "subagent";
                  model = "zai-coding-plan/glm-4.7-flash";
                };
              };

              keybinds = {
                app_exit = "ctrl+c";
                messages_half_page_up = "ctrl+u";
                messages_half_page_down = "ctrl+d";
                input_newline = "shift+enter";
              };

              lsp = {
                nixd = {
                  command = [ "nixd" ];
                  extensions = [ ".nix" ];
                };

                qmlls = {
                  command = [ "qmlls" ];
                  extensions = [ ".qml" ];
                };
              };

              formatter = {
                rustfmt = {
                  command = [
                    "cargo"
                    "fmt"
                    "--"
                    "$FILE"
                  ];
                  extensions = [ ".rs" ];
                };
                qmlformat = {
                  command = [
                    "qmlformat"
                    "--inplace"
                    "$FILE"
                  ];
                  extensions = [ ".qml" ];
                };
              };

              provider.zai-coding-plan = {
                options.timeout = 600000;
                models =
                  let
                    inherit (lib.attrsets) genAttrs;
                    inherit (lib) elem;

                    models = [
                      "glm-5.1"
                      "glm-5"
                      "glm-5-turbo"
                      "glm-4.7"
                      "glm-4.7-flashx"
                      "glm-4.7-flash"
                      "glm-4.6"
                      "glm-4.5"
                      "glm-4.5-x"
                      "glm-4.5-air"
                      "glm-4.5-airx"
                      "glm-4.5-flash"
                    ];

                    supportsToolStreaming = [
                      "glm-5.1"
                      "glm-5"
                      "glm-5-turbo"
                    ];
                  in
                  genAttrs models (name: {
                    options = {
                      tool_stream = elem name supportsToolStreaming;
                      stream = true;
                      thinking.type = "enabled";
                    };
                  });
              };

              mcp = {
                context7 = {
                  type = "remote";
                  url = "https://mcp.context7.com/mcp";
                  headers = {
                    CONTEXT7_API_KEY = "{file:${secrets.context7Key.path}}";
                  };
                };

                gh_grep = {
                  type = "remote";
                  url = "https://mcp.grep.app";
                };

                web-reader = {
                  type = "remote";
                  url = "https://api.z.ai/api/mcp/web_reader/mcp";
                  headers = {
                    Authorization = "Bearer {file:${secrets.zaiKey.path}}";
                  };
                };

                web-search-prime = {
                  type = "remote";
                  url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
                  headers = {
                    Authorization = "Bearer {file:${secrets.zaiKey.path}}";
                  };
                };

                zread = {
                  type = "remote";
                  url = "https://api.z.ai/api/mcp/zread/mcp";
                  headers = {
                    Authorization = "Bearer {file:${secrets.zaiKey.path}}";
                  };
                };

                nixos = {
                  type = "local";
                  command = [
                    "${getExe pkgs.nix}"
                    "run"
                    "github:utensils/mcp-nixos"
                    "--"
                  ];
                };
              };
            };
          };
        };
      };
    };

  claudeCodeBase =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.attrsets) genAttrs;
      inherit (lib.meta) getExe;
      inherit (lib.strings) toJSON replaceStrings;
      inherit (lib.trivial) const;
    in
    {
      # THANK YOU FOR THIS ENTIRE THING!!
      # Xitter: @HSVSphere
      # Source: <https://github.com/RGBCube/ncc/blob/dentride/modules/slop.mod.nix>
      hjem.extraModule =
        { config, osConfig, ... }:
        let
          inherit (osConfig.age) secrets;
        in
        {
          # For compatibility.
          # Retarded 500k loc crap refuses to follow XDG spec.
          files.".claude/CLAUDE.md" = {
            type = "copy";
            text = instructions;
          };

          xdg.config.files = {
            "claude-code/CLAUDE.md" = {
              type = "copy";
              text = instructions;
            };

            "claude-code/settings.json" = {
              type = "copy"; # Sometimes needs to write to config.
              generator = pkgs.writers.writeJSON "claude-code-settings.json";
              value = {
                "$schema" = "https://json.schemastore.org/claude-code-settings.json";

                permissions.allow = map (cmd: "Bash(${replaceStrings [ "*" ] [ ":*" ] cmd})") commands.allow ++ [
                  "Glob"
                  "Grep"
                  "Read"
                  "LSP"
                  "WebFetch"
                  "WebSearch"
                  "TaskCreate"
                  "TaskUpdate"
                  "TaskGet"
                  "TaskList"
                  "TaskOutput"
                  "TaskStop"

                  "mcp__context7"
                  "mcp__web-reader"
                  "mcp__web-search-prime"
                  "mcp__zread"
                ];

                sandbox = {
                  enabled = true;
                  filesystem = {
                    allowWrite = [ "/tmp" ];
                    denyRead = [
                      "/run/agenix"
                      "/run/agenix.d"
                    ];
                  };

                };

                env = {
                  # For z.ai coding plan.
                  ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
                  API_TIMEOUT_MS = "3000000";
                  ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.7-flash";
                  ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5.1";
                  ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.1";

                  CLAUDE_BASH_NO_LOGIN = "1";
                  CLAUDE_CODE_EAGER_FLUSH = "1";
                  CLAUDE_CODE_FORCE_GLOBAL_CACHE = "1";
                  MCP_CONNECTION_NONBLOCKING = "1";
                  USE_BUILTIN_RIPGREP = "0";

                  CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1";
                  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
                  CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY = "20";
                  CLAUDE_CODE_PLAN_V2_AGENT_COUNT = "5";
                  CLAUDE_CODE_PLAN_V2_EXPLORE_AGENT_COUNT = "5";
                  DISABLE_AUTO_COMPACT = "1";
                  ENABLE_MCP_LARGE_OUTPUT_FILES = "1";
                  ENABLE_TOOL_SEARCH = "auto:5";
                  MAX_THINKING_TOKENS = "31999";

                  CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
                  DISABLE_AUTOUPDATER = "1";
                  DISABLE_ERROR_REPORTING = "1";
                  DISABLE_INSTALLATION_CHECKS = "1";
                  DISABLE_TELEMETRY = "1";

                  CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
                  CLAUDE_CODE_HIDE_ACCOUNT_INFO = "1";
                  DISABLE_COST_WARNINGS = "1";
                };

                alwaysThinkingEnabled = true;

                skipWebFetchPreflight = true;

                hooks.WorktreeCreate = singleton {
                  hooks = singleton {
                    type = "command";
                    command = # bash
                      ''jj workspace add "$(cat /dev/stdin | jq '.name' --raw-output)"'';
                  };
                };
                hooks.WorktreeRemove = singleton {
                  hooks = singleton {
                    type = "command";
                    command = # bash
                      ''jj workspace forget "$(cat /dev/stdin | jq '.worktree_path' --raw-output)"'';
                  };
                };

                enabledPlugins = genAttrs [
                  "code-review@claude-plugins-official"
                  "code-simplifier@claude-plugins-official"
                  "context7@claude-plugins-official"
                  "ralph-loop@claude-plugins-official"
                  "rust-analyzer-lsp@claude-plugins-official"
                ] (const true);

                attribution = {
                  commit = "";
                  pr = "";
                };
              };
            };
          };

          # Helper script for adding MCP servers.
          # Should probably use writeScriptBin but idc, I run it once.
          files."claude-mcp-setup" = {
            text = # nu
              ''
                #!/usr/bin/env nu
                try { claude mcp add -s user -t http context7 https://mcp.context7.com/mcp --header $"CONTEXT7_API_KEY: (cat ${secrets.context7Key.path})" }
                try { claude mcp add -s user -t http web-reader https://api.z.ai/api/mcp/web_reader/mcp --header $"Authorization: Bearer (cat ${secrets.zaiKey.path})" }
                try { claude mcp add -s user -t http web-search-prime https://api.z.ai/api/mcp/web_search_prime/mcp --header $"Authorization: Bearer (cat ${secrets.zaiKey.path})" }
                try { claude mcp add -s user -t http zread https://api.z.ai/api/mcp/zread/mcp --header $"Authorization: Bearer (cat ${secrets.zaiKey.path})" }
              '';
            executable = true;
          };

          packages =
            let
              patch =
                pkgs.writeScriptBin "patch-claude-code-src" # python
                  ''
                    #!${getExe pkgs.python3}
                    from __future__ import annotations

                    import re
                    import sys
                    from collections.abc import Callable
                    from pathlib import Path
                    from typing import Union

                    type Replacement = Union[bytes, Callable[[re.Match[bytes]], bytes]]

                    W: bytes = rb"[\w$]+"
                    data: bytes = Path(sys.argv[1]).read_bytes()

                    SEARCH_WINDOW: int = 500


                    def log(msg: str) -> None:
                      sys.stderr.write(msg + "\n")


                    def patch(label: str, pattern: bytes, replacement: Replacement) -> None:
                      global data
                      data, n = re.subn(pattern, replacement, data)
                      log(f"{label} ({n})")


                    def flip_gates(gates: list[tuple[bytes, str]]) -> None:
                      """Flip all gate defaults from false to true in a single regex pass."""
                      global data
                      gate_keys: list[bytes] = [g for g, _ in gates]
                      labels: dict[bytes, str] = dict(gates)
                      alternation: bytes = b"|".join(re.escape(g) for g in gate_keys)
                      pat: bytes = W + rb'\("(' + alternation + rb')",!1\)'
                      flipped: set[bytes] = set()

                      def replacer(m: re.Match[bytes]) -> bytes:
                        flipped.add(m.group(1))
                        return m[0].replace(b",!1)", b",!0)")

                      data, n = re.subn(pat, replacer, data)
                      log(f"feature gates: {n} flipped across {len(flipped)} gates")
                      for key in gate_keys:
                        status = "ok" if key in flipped else "MISSED"
                        log(f"  {labels[key]} [{status}]")


                    # --- AGENTS.md support ---
                    # The CLAUDE.md loader only reads CLAUDE.md. Patch it to also load AGENTS.md
                    # from the same directories. Pattern: let VAR=ME(DIR,"CLAUDE.md");ARR.push(...await XE(VAR,"Project",ARG,BOOL))

                    agents_pat: bytes = (
                      rb"let (" + W + rb")=(" + W + rb")\((" + W + rb'),"CLAUDE\.md"\);'
                      rb"(" + W + rb")\.push\(\.\.\.await (" + W + rb")\(\1,\"Project\",(" + W + rb"),(" + W + rb")\)\)"
                    )


                    def agents_repl(m: re.Match[bytes]) -> bytes:
                      var, join_fn, dir_, arr, load_fn, arg, flag = [m.group(i) for i in range(1, 8)]
                      return (
                        b'for(let _f of["CLAUDE.md","AGENTS.md"]){let '
                        + var + b"=" + join_fn + b"(" + dir_ + b",_f);"
                        + arr + b".push(...await " + load_fn + b"(" + var + b',"Project",' + arg + b"," + flag + b"))}"
                      )


                    patch("agents.md loader", agents_pat, agents_repl)

                    # --- macOS config path ---

                    data = data.replace(
                      b'case"macos":return"/Library/Application Support/ClaudeCode"',
                      b'case"macos":return"/etc/claude-code"',
                    )

                    # --- Enable hard-disabled slash commands ---

                    slash_commands: list[tuple[bytes, str]] = [
                      (b'name:"btw",description:"Ask a quick side question', "/btw"),
                      (b'name:"bridge-kick",description:"Inject bridge failure states', "/bridge-kick"),
                      (b'name:"files",description:"List all files currently in context"', "/files"),
                      (b'name:"tag",userFacingName', "/tag"),
                    ]

                    for anchor, label in slash_commands:
                      pos: int = data.find(anchor)
                      if pos < 0:
                        log(f"slash command {label}: NOT FOUND")
                        continue
                      window: bytes = data[pos : pos + SEARCH_WINDOW]
                      patched: bytes = window.replace(b"isEnabled:()=>!1", b"isEnabled:()=>!0", 1)
                      if patched == window:
                        log(f"slash command {label}: isEnabled not found in window")
                        continue
                      data = data[:pos] + patched + data[pos + SEARCH_WINDOW :]
                      log(f"slash command {label}: enabled")

                    # --- Bypass telemetry gate in feature flag checker ---
                    # With telemetry off, ed() returns false and all 9 call sites bail out,
                    # blocking feature flags, GrowthBook refresh, and the async qc() path
                    # used by remote control. Make ed() always return true so the flag
                    # infrastructure works even with DISABLE_TELEMETRY=1.

                    patch(
                      "telemetry gate (ed → true)",
                      rb"function ed\(\)\{return " + W + rb"\(\)\}",
                      lambda m: m[0].replace(b"return ", b"return!0||"),
                    )

                    # --- Fix Deno-compile bridge spawn ---
                    # Deno-compiled binaries eat --flags as V8 args, so we route spawns through
                    # env(1) to pass them as normal CLI flags instead.

                    patch(
                      "deno bridge spawn fix",
                      rb"let (" + W + rb")=(" + W + rb")\((" + W + rb")\.execPath,(" + W + rb"),",
                      lambda m: (
                        b"let "
                        + m[1]
                        + b"="
                        + m[2]
                        + b'("env",["--",'
                        + m[3]
                        + b".execPath,..."
                        + m[4]
                        + b"],"
                      ),
                    )

                    # --- Flip feature gates ---
                    # DISABLE_TELEMETRY=1 prevents GrowthBook feature flag resolution, so all gates
                    # fall back to their hardcoded defaults (false). Flip them to true.

                    Gate = tuple[bytes, str]

                    core_gates: list[Gate] = [
                      (b"tengu_ccr_bridge", "remote control"),
                      (b"tengu_bridge_repl_v2", "remote control v2 (envless)"),
                      (b"tengu_bridge_system_init", "bridge SDK init on connect"),
                      (b"tengu_remote_backend", "remote backend"),
                      (b"tengu_keybinding_customization_release", "custom keybindings"),
                      (b"tengu_immediate_model_command", "instant /model switching"),
                      (b"tengu_fgts", "fine-grained tool streaming"),
                      (b"tengu_auto_background_agents", "background agent timeout"),
                      (b"tengu_pid_based_version_locking", "PID version locking"),
                      (b"tengu_plan_mode_interview_phase", "plan mode interview"),
                      (b"tengu_surreal_dali", "scheduled agents/cron"),
                    ]

                    memory_gates: list[Gate] = [
                      # (b"tengu_session_memory", "session memory"),  # auto-memory; pollutes unrelated convos
                      (b"tengu_sm_compact", "memory survives compaction"),
                      (b"tengu_compact_cache_prefix", "cache-aware compaction"),
                      (b"tengu_compact_streaming_retry", "compact stream retry"),
                      (b"tengu_pebble_leaf_prune", "message pruning"),
                      (b"tengu_herring_clock", "team memory directory"),
                      (b"tengu_passport_quail", "typed combined memory prompts"),
                      # (b"tengu_swinburne_dune", "new memory extraction prompts"),  # auto-extraction
                    ]

                    ux_gates: list[Gate] = [
                      (b"tengu_coral_fern", "grep hints in prompt"),
                      (b"tengu_kairos_brief", "brief output mode"),
                      (b"tengu_permission_explainer", "permission explanations"),
                      (b"tengu_destructive_command_warning", "destructive command warnings"),
                      (b"tengu_pr_status_cli", "PR status footer"),
                      (b"tengu_quiet_hollow", "thinking summaries"),
                      (b"tengu_lean_cast", "lean system prompt"),
                      (b"tengu_amber_prism", "permission denial context"),
                      (b"tengu_sepia_heron", "token saver (compress tool output)"),
                      (b"tengu_hawthorn_steeple", "context windowing"),
                    ]

                    tool_gates: list[Gate] = [
                      (b"tengu_mcp_elicitation", "MCP tool prompting"),
                      (b"tengu_tool_input_aliasing", "param alias resolution"),
                      (b"tengu_chrome_auto_enable", "auto-enable chrome devtools"),
                      (b"tengu_copper_bridge", "chrome bridge context"),
                      (b"tengu_system_prompt_global_cache", "global system prompt cache"),
                      (b"tengu_tst_hint_m7r", "tool search hints"),
                      (b"tengu_tst_kx7", "auto tool search"),
                      (b"tengu_glacier_2xr", "deferred tool improvements"),
                      (b"tengu_defer_caveat_m9k", "deferred tool hint in prompt"),
                      (b"tengu_basalt_3kr", "MCP instruction delta"),
                      (b"tengu_cobalt_frost", "voice conversation engine"),
                      (b"tengu_scarf_coffee", "API context management"),
                      (b"tengu_granite_whisper", "repo file indexing"),
                      (b"tengu_plum_vx3", "web search reranking"),
                      (b"tengu_quartz_lantern", "remote tool use diff"),
                      (b"tengu_marble_anvil", "thinking edits"),
                      # (b"tengu_moth_copse", "relevant memory recall"),  # auto-recall; pollutes unrelated convos
                      (b"tengu_cork_m4q", "batch command processing"),
                    ]

                    flip_gates(core_gates + memory_gates + ux_gates + tool_gates)

                    # --- Bump background agent timeout from 120s to 240s ---

                    patch(
                      "background agent timeout",
                      rb'"tengu_auto_background_agents",![01]\)\)return 120000',
                      lambda m: m[0].replace(b"120000", b"240000"),
                    )

                    # --- Kill claude-developer-platform bundled skill ---

                    data = data.replace(
                      b'name:"claude-developer-platform",description:`',
                      b'name:"claude-developer-platform",isEnabled:()=>!1,description:`',
                    )
                    log("killed claude-developer-platform skill")

                    # --- Replace usage fetch with self-contained OAuth implementation ---
                    # FO()/eO() falls back to x-api-key when dA()/nA() returns false (telemetry off),
                    # but /api/oauth/usage requires Bearer + oauth beta header. Replace the entire
                    # function with a Deno-native implementation that reads credentials directly.

                    usage_fn_pat: bytes = (
                      rb"async function (" + W + rb")\(\)\{"
                      rb"(?:if\(!" + W + rb"\(\)\|\|!" + W + rb"\(\)\)return\{\};)?"
                      rb"let " + W + rb"=" + W + rb"\(\);if\(" + W + rb"&&" + W + rb"\(" + W + rb"\." + W + rb"\)\)return null;"
                      rb"let " + W + rb"=" + W + rb"\(\);if\(" + W + rb"\.error\)throw Error\(\x60Auth error: \x24\{" + W + rb"\.error\}\x60\);"
                      rb"let " + W + rb"=\{[^}]+\}," + W + rb"=\x60\x24\{(" + W + rb")\(\)\.(" + W + rb")\}/api/oauth/usage\x60;"
                      rb"return\(await (" + W + rb")\.get\(" + W + rb",\{headers:" + W + rb",timeout:5000\}\)\)\.data\}"
                    )

                    usage_fn_match: re.Match[bytes] | None = re.search(usage_fn_pat, data)
                    if usage_fn_match:
                      fn_name: bytes = usage_fn_match.group(1)
                      config_fn: bytes = usage_fn_match.group(2)
                      base_url_key: bytes = usage_fn_match.group(3)
                      http_client: bytes = usage_fn_match.group(4)
                      replacement: bytes = (
                        b"async function " + fn_name + b"(){"
                        b"const _cd=(process.env.CLAUDE_CONFIG_DIR||"
                        b'(Deno.env.get("HOME")+"/.config/claude"));'
                        b"let _tk;"
                        b'try{const _cr=JSON.parse(new TextDecoder().decode('
                        b'Deno.readFileSync(_cd+"/.credentials.json")));'
                        b"_tk=_cr?.claudeAiOauth?.accessToken}catch{return{}}"
                        b"if(!_tk)return{};"
                        b'const _cp="/tmp/.claude-usage-"+_tk.slice(-8)+".json";'
                        b"try{const _s=Deno.statSync(_cp);"
                        b"if(Date.now()-_s.mtime.getTime()<60000)"
                        b'return JSON.parse(new TextDecoder().decode(Deno.readFileSync(_cp)))}catch{}'
                        b"const _h={" + b'"Content-Type":"application/json",'
                        b'"Authorization":"Bearer "+_tk,'
                        b'"anthropic-beta":"oauth-2025-04-20"};'
                        b"const _u=`''${" + config_fn + b"()." + base_url_key + b"}/api/oauth/usage`;"
                        b"const _r=(await " + http_client + b".get(_u,{headers:_h,timeout:5000})).data;"
                        b'try{Deno.writeTextFileSync(_cp,JSON.stringify(_r))}catch{}'
                        b"return _r}"
                      )
                      data = data.replace(usage_fn_match[0], replacement)
                      log("usage fetch: replaced")
                    else:
                      log("usage fetch: pattern NOT FOUND")

                    Path(sys.argv[1]).write_bytes(data)
                  '';

              claudeScript =
                pkgs.writeScriptBin "claude" # nu
                  ''
                    #!${getExe pkgs.nushell}

                    def --wrapped main [--rebuild, ...arguments] {
                      let cache_global = $env
                      | get --optional "XDG_CACHE_HOME"
                      | default ($env.HOME | path join ".cache")

                      let cache = $cache_global | path join "claude-code"

                      # let version = "2.1.70"
                      let version = do {
                        let version_file = $cache | path join "latest-version"

                        match (try { (date now) - (ls $version_file | get 0.modified) > 6hr }) {
                          # Version older than 6h or doesn't exist.
                          true | null => {
                            let version = try {
                              http get --max-time 5sec https://registry.npmjs.org/@anthropic-ai/claude-code/latest | get version
                            } catch {
                              print --stderr $"(ansi yellow_bold)warn:(ansi reset) fetched version older than 6hr, but can't re-fetch"
                              return ""
                            }

                            try {
                              $version_file | path parse | get parent | mkdir $in
                              $version | save --force $version_file
                            } catch {
                              print --stderr $"(ansi yellow_bold)warn:(ansi reset) failed to save latest fetched version"
                            }

                            $version
                          },

                          # Version fetched within 6h.
                          false => { try {
                            open $version_file
                          } catch {
                            print --stderr $"(ansi yellow_bold)warn:(ansi reset) failed to read latest fetched version"
                            ""
                          } },
                        }
                      }

                      let binary_path = if ($version | is-empty) {
                        print --stderr $"(ansi yellow_bold)warn:(ansi reset) falling back to latest binary"

                        try {
                          glob ($cache)/claude-code-* | last
                        } catch {
                          print --stderr $"(ansi red_bold)error:(ansi reset) no binary found"
                          exit 67
                        }
                      } else {
                        $cache | path join $"claude-code-($version)"
                      }

                      if not ($binary_path | path exists) or $rebuild {
                        ${getExe pkgs.deno} cache $"npm:@anthropic-ai/claude-code@($version)"
                        ${getExe patch} ($cache_global | path join "deno" "npm" "registry.npmjs.org" "@anthropic-ai" "claude-code" $version "cli.js")
                        ${getExe pkgs.deno} compile --allow-all --output $binary_path $"npm:@anthropic-ai/claude-code@($version)"
                      }

                      $env.PATH ++= [ "${pkgs.ripgrep}/bin" ]
                      r#'${
                        toJSON config.xdg.config.files."claude-code/settings.json".value.env
                      }'# | from json | load-env

                      exec $binary_path ...$arguments
                    }
                  '';
            in
            [
              (pkgs.symlinkJoin {
                name = "claude-wrapped";
                paths = singleton claudeScript;
                buildInputs = singleton pkgs.makeWrapper;

                # This just allows skipping permissions - not enabled by default.
                postBuild = ''
                  wrapProgram $out/bin/claude \
                    --add-flags "--allow-dangerously-skip-permissions" \
                    --run 'export ANTHROPIC_AUTH_TOKEN="$(cat ${secrets.zaiKey.path})"'
                '';
              })

              # claude-code sandbox deps.
              pkgs.socat
              pkgs.bubblewrap
            ];
        };
    };

  aiExtra =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      opencodeDesktopPackage = pkgs.symlinkJoin {
        name = "opencode-desktop-wrapped";
        paths = singleton pkgs.opencode-desktop;
        buildInputs = singleton pkgs.makeWrapper;
        postBuild = # sh
          ''
            wrapProgram $out/bin/OpenCode \
              --prefix GST_PLUGIN_PATH : "${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0" \
              --set OPENCODE_EXPERIMENTAL true \
              --set OPENCODE_ENABLE_EXA 1
          '';
      };
    in
    {
      hjem.extraModules = singleton {
        packages = [
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.agentfs
          pkgs.codex
          pkgs.gemini-cli
          opencodeDesktopPackage
          pkgs.qwen-code
        ];
      };
    };
in
{
  flake.modules.nixos.opencode = opencodeBase;
  flake.modules.darwin.opencode = opencodeBase;

  flake.modules.nixos.claude-code = claudeCodeBase;
  flake.modules.darwin.claude-code = claudeCodeBase;

  flake.modules.nixos.ai-extra = aiExtra;
  flake.modules.darwin.ai-extra = aiExtra;
}
