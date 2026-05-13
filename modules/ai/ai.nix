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
in
{
  flake.modules.common.opencode =
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
      hjem.extraModule = {
        packages = [
          pkgs.python3
          pkgs.uv
          opencodePackage
        ];

        xdg.config.files = {
          "opencode/AGENTS.md" = {
            type = "copy";
            source = ./AGENTS.md;
          };

          "opencode/opencode.jsonc" = {
            generator = pkgs.writers.writeJSON "opencode-opencode.jsonc";
            value = {
              theme = "gruvbox";
              autoupdate = false;
              model = "opencode-go/minimax-m2.7";
              small_model = "opencode-go/minimax-m2.5";

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
                  model = "opencode-go/minimax-m2.7";
                };

                researcher = {
                  mode = "primary";
                  model = "opencode-go/minimax-m2.7";
                  description = "Read-only research primarily using the web";
                };

                explore = {
                  mode = "subagent";
                  model = "opencode-go/minimax-m2.7";
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

  flake.modules.common.claude-code =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton optionals;
      inherit (lib.attrsets) genAttrs;
      inherit (lib.meta) getExe getExe';
      inherit (lib.strings) toJSON;
      inherit (lib.trivial) const;
    in
    {
      # THANK YOU FOR THIS ENTIRE THING!!
      # Xitter: @HSVSphere
      # Source: <https://github.com/RGBCube/ncc/blob/dentride/modules/slop.mod.nix>
      hjem.extraModule =
        { config, osConfig, ... }:
        {
          # TODO: Retarded 500k loc crap refuses to follow XDG spec.
          # I will fix this system-wide when I cba figuring out how to do it well.
          files = {
            ".claude/CLAUDE.md" = {
              type = "copy";
              source = ./CLAUDE_AGENTS.md;
            };

            ".claude/settings.json" = {
              type = "copy"; # Sometimes needs to write to config.
              generator = pkgs.writers.writeJSON "claude-code-settings.json";
              value = {
                "$schema" = "https://json.schemastore.org/claude-code-settings.json";

                permissions.allow = map (cmd: "Bash(${cmd})") commands.allow ++ [
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
                  ANTHROPIC_BASE_URL = "http://localhost:4000";
                  API_TIMEOUT_MS = "3000000";
                  ANTHROPIC_MODEL = "deepseek-v4-flash";
                  ANTHROPIC_SMALL_FAST_MODEL = "deepseek-v4-flash";
                  CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash";
                  ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash";
                  ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-flash";
                  ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-v4-pro";

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
                  CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS = "1";

                  CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
                  CLAUDE_CODE_HIDE_ACCOUNT_INFO = "1";
                  DISABLE_COST_WARNINGS = "1";

                  CAVEMAN_DEFAULT_MODE = "ultra";
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

                hooks.Notification = singleton {
                  matcher = "";
                  hooks = singleton {
                    type = "command";
                    command = # bash
                      ''zellij pipe --name "zellij-attention::waiting::$ZELLIJ_PANE_ID"'';
                  };
                };
                hooks.Stop = singleton {
                  hooks = singleton {
                    type = "command";
                    command = # bash
                      ''zellij pipe --name "zellij-attention::completed::$ZELLIJ_PANE_ID"'';
                  };
                };

                enabledPlugins = genAttrs [
                  "code-review@claude-plugins-official"
                  "code-simplifier@claude-plugins-official"
                  "context7@claude-plugins-official"
                  "ralph-loop@claude-plugins-official"
                  "rust-analyzer-lsp@claude-plugins-official"
                  "caveman@caveman"
                ] (const true);

                extraKnownMarketplaces = {
                  caveman.source = {
                    source = "github";
                    repo = "JuliusBrussee/caveman";
                  };
                };

                attribution = {
                  commit = "";
                  pr = "";
                };
              };
            };
          };

          packages =
            let
              lift = pkgs.writeScriptBin "lift-claude-bun" /* py */ ''
                #!${getExe pkgs.python3}
                from __future__ import annotations

                # Extract the cli.js bundle from a bun --compile --bytecode executable.
                #
                # Starting with @anthropic-ai/claude-code 2.1.113 the npm package stopped
                # shipping cli.js and instead publishes platform-specific tarballs that contain
                # a bun-compiled ELF (~226 MB). The JavaScript is still fully embedded in the
                # binary as plaintext — the @bytecode marker just means a V8 parse-cache lives
                # alongside it, not instead of it.
                #
                # Layout of each CJS module inside the bun SEA payload:
                #   // @bun[ @bytecode] @bun-cjs\n
                #   (function(exports, require, module, __filename, __dirname) {<BODY>})\n
                #   \x00/$bunfs/root/<next-module-name>\x00...
                #
                # Claude Code ships three real modules in the tail region (past 0x6000000):
                # the main cli (~12 MB), then two tiny native-loader stubs for the optional
                # image-processor.node and audio-capture.node. Only the first is interesting.

                import sys
                from pathlib import Path

                # Skip over .rodata / .text — those contain `// @bun` string literals (error
                # messages, help text) that would confuse the scanner. The first real module
                # sat at ~0xd333ec8 in 2.1.113; staying well below that survives future growth.
                SCAN_FROM: int = 0x6000000

                HEADERS: list[bytes] = [
                  b"// @bun @bytecode @bun-cjs\n(function(exports, require, module, __filename, __dirname) {",
                  b"// @bun @bun-cjs\n(function(exports, require, module, __filename, __dirname) {",
                ]

                CJS_OPEN: bytes = b"(function(exports, require, module, __filename, __dirname) {"
                CJS_END: bytes = b"})\n\x00"


                def find_main_module(data: bytes) -> tuple[int, int]:
                  # In 2.1.117 bun emits cli.js twice: once as a @bytecode blob with the V8
                  # parse cache interleaved between the source and its `})\n\x00` terminator,
                  # and again as a clean source-only copy that terminates normally. Collect
                  # every header past SCAN_FROM and pick the first one whose terminator lies
                  # before the next header — that's the source-only copy.
                  headers: list[tuple[int, int]] = []
                  for header in HEADERS:
                    p: int = SCAN_FROM
                    while True:
                      p = data.find(header, p)
                      if p < 0:
                        break
                      headers.append((p, len(header)))
                      p += 1

                  if not headers:
                    sys.exit("lift: no bun CJS module header found past 0x6000000")

                  headers.sort()
                  boundaries: list[int] = [p for p, _ in headers] + [len(data)]

                  for idx, (start, _) in enumerate(headers):
                    next_header: int = boundaries[idx + 1]
                    end: int = data.find(CJS_END, start, next_header)
                    if end >= 0:
                      return start, end + 3  # include })\n, exclude trailing NUL

                  sys.exit("lift: could not find module terminator (})\\n\\x00)")


                def unwrap(mod: bytes) -> bytes:
                  nl = mod.find(b"\n")
                  if nl < 0:
                    sys.exit("lift: module has no header newline")
                  body = mod[nl + 1 :]
                  if not body.startswith(CJS_OPEN):
                    sys.exit("lift: module does not open with expected CJS wrapper")
                  body = body[len(CJS_OPEN) :]
                  # tail is either `})\n` or `})`
                  if body.endswith(b"})\n"):
                    body = body[:-3]
                  elif body.endswith(b"})"):
                    body = body[:-2]
                  else:
                    sys.exit("lift: module does not end with `})` wrapper close")
                  return body


                def main() -> None:
                  if len(sys.argv) != 3:
                    sys.exit("usage: lift-claude-bun <claude-binary> <output.cjs>")

                  binary = Path(sys.argv[1])
                  output = Path(sys.argv[2])

                  data = binary.read_bytes()
                  start, end = find_main_module(data)
                  body = unwrap(data[start:end])

                  # Sanity: the real claude-code cli.js always contains this legal banner.
                  if b"Anthropic" not in body[:4096]:
                    sys.exit("lift: extracted body is missing Anthropic banner — layout changed?")

                  output.write_bytes(body)
                  sys.stderr.write(
                    f"lifted {len(body):,} bytes from {binary.name} "
                    f"(module @ {start:#x}..{end:#x}) -> {output}\n"
                  )


                if __name__ == "__main__":
                  main()
              '';

              patch = pkgs.writeScriptBin "patch-claude-code-src" /* py */ ''
                #!${getExe pkgs.python3}
                from __future__ import annotations

                import re
                import sys
                from collections.abc import Callable
                from pathlib import Path
                from typing import Union

                type Replacement = Union[bytes, Callable[[re.Match[bytes]], bytes]]

                W: bytes = rb"[\w$]+"
                # Qualified name: matches `FN` and also `NS.FN` (e.g. `Lf.join`, `Oc7.spawn`).
                # Since 2.1.113 bun's bundler emits more member-style calls for path/spawn helpers.
                Q: bytes = rb"[\w$]+(?:\.[\w$]+)*"
                data: bytes = Path(sys.argv[1]).read_bytes()

                SEARCH_WINDOW: int = 500


                def log(msg: str) -> None:
                  sys.stderr.write(msg + "\n")


                def patch(label: str, pattern: bytes, replacement: Replacement) -> None:
                  global data
                  data, n = re.subn(pattern, replacement, data)
                  log(f"{label} ({n})")


                def replace(label: str, old: bytes, new: bytes) -> None:
                  global data
                  n: int = data.count(old)
                  if n == 0:
                    log(f"{label}: NOT FOUND")
                    return
                  data = data.replace(old, new)
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
                  rb"let (" + W + rb")=(" + Q + rb")\((" + W + rb'),"CLAUDE\.md"\);'
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

                replace(
                  "macOS config path",
                  b'case"macos":return"/Library/Application Support/ClaudeCode"',
                  b'case"macos":return"/etc/claude-code"',
                )

                # --- Enable hard-disabled slash commands ---

                slash_commands: list[tuple[bytes, str]] = [
                  (b'name:"btw",description:"Ask a quick side question', "/btw"),
                  (b'name:"bridge-kick",description:"Inject bridge failure states', "/bridge-kick"),
                  (b'name:"files",description:"List all files currently in context"', "/files"),
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
                # The chain is: h8(featureGate) bails to default if !Qo(); Qo()=Ew6();
                # Ew6()=!Cq6(); Cq6() returns true when on bedrock/vertex/foundry OR when
                # user-facing telemetry is disabled (s_1()/equivalent). Drop the trailing
                # telemetry-disabled check so feature gates still resolve with
                # DISABLE_TELEMETRY=1 while preserving the bedrock/vertex/foundry detection.
                # Anchor on the stable env-var literal CLAUDE_CODE_USE_BEDROCK; the obfuscated
                # function name (Cq6) and the trailing wrapper name (s_1) both rotate.

                patch(
                  "telemetry gate (drop telemetry-disabled check)",
                  (
                    rb"function (" + W + rb")\(\)\{return (" + W + rb")\(process\.env\.CLAUDE_CODE_USE_BEDROCK\)"
                    rb"\|\|\2\(process\.env\.CLAUDE_CODE_USE_VERTEX\)"
                    rb"\|\|\2\(process\.env\.CLAUDE_CODE_USE_FOUNDRY\)"
                    rb"\|\|" + W + rb"\(\)\}"
                  ),
                  lambda m: re.sub(rb"\|\|" + W + rb"\(\)\}$", b"||!1}", m[0]),
                )

                # --- Force Av() async-gate to always resolve true ---
                # Av(flag) is the ASYNC feature-gate resolver. It short-circuits to its default
                # in two places when telemetry is off: an inline `if(!va())return!1;` AND the
                # same check inside Irq() which it delegates to. Since Av() hardcodes !1 as the
                # default passed to Irq, dropping only the inline guard leaves Irq returning
                # false anyway.
                #
                # Every Av() call-site in 2.1.113 targets a gate we intentionally want enabled:
                #  - tengu_ccr_bridge          → Qr8() → initReplBridge() auto-connect
                #  - tengu_ccr_bridge_multi_session → multi-session remote control
                #  - tengu_ccr_bundle_seed_enabled  → CCR bundle seed
                #  - tengu_harbor             → plugin marketplace
                # None of these are things we want off. Replace the whole body to return !0.
                # Safe because Av() never writes telemetry — it only reads cached flag state.

                patch(
                  "Av() force-true for telemetry-off builds",
                  # Negative lookahead keeps the body match from extending past the end of Av
                  # into the next function definition (a previous version matched `async
                  # function Bb8(...)` and spanned through Av's tail, obliterating both).
                  # The inner resolver name (Irq → aeq → ...) rotates across versions, so
                  # capture it rather than pinning to a literal.
                  rb"async function (" + W + rb")\(H\)\{(?:(?!async function ).){60,400}?return " + W + rb"\(H,!1,!0\)\}",
                  lambda m: b"async function " + m[1] + b"(H){return !0}",
                )

                # --- Restore 1h prompt cache TTL when telemetry is off ---
                # https://github.com/anthropics/claude-code/issues/45381
                # The GrowthBook allowlist for "ttl":"1h" cache_control falls back to the
                # default object when telemetry is off. Anthropic now ships
                # {allowlist:["repl_main_thread*","sdk","auto_mode"]} as the default (up
                # from the broken {} in earlier versions), so the TUI and SDK already get
                # 1h TTL — but batch agents and less-common query sources still miss.
                # Widen the default to ["*"] so everything matches.

                patch(
                  "1h prompt cache TTL fallback",
                  rb'(' + W + rb')\("tengu_prompt_cache_1h_config",\{allowlist:\[[^\]]+\]\}\)\.allowlist\?\?\[\]',
                  lambda m: m[1] + b'("tengu_prompt_cache_1h_config",{allowlist:["*"]}).allowlist??[]',
                )

                # --- Disable tengu_keybindings_dom (new chord dispatcher) ---
                # 2.1.118 introduced a DOM-style chord/focus keybinding system behind
                # this gate (default !0). The new system wraps the TUI in a programmatic
                # focus manager; during /rewind the message selector unmounts and
                # remounts in a sequence where the focus target goes null long enough
                # that keystrokes stop routing — stdin pauses, fd 0 drops out of epoll,
                # Ctrl-C (raw 0x03 in raw mode) has no reader. Wedges the TUI hard.
                # The 117-era dispatcher is still present as the `: old_path` branch
                # of every gt()?new:old site; flipping the default reverts to it.

                patch(
                  "disable new keybindings dispatcher (causes /rewind hang in 2.1.118)",
                  rb'(' + W + rb')\("tengu_keybindings_dom",!0\)',
                  lambda m: m[1] + b'("tengu_keybindings_dom",!1)',
                )

                # --- Fix Deno-compile bridge spawn ---
                # Deno-compiled binaries eat --flags as V8 args, so we route spawns through
                # env(1) to pass them as normal CLI flags instead.

                patch(
                  "deno bridge spawn fix",
                  rb"let (" + W + rb")=(" + Q + rb")\((" + W + rb")\.execPath,(" + W + rb"),",
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
                  (b"tengu_bridge_system_init", "bridge SDK init on connect"),
                  (b"tengu_bridge_client_presence_enabled", "bridge presence heartbeats"),
                  (b"tengu_bridge_requires_action_details", "bridge rich tool-use payloads"),
                  (b"tengu_remote_backend", "remote backend"),
                  (b"tengu_immediate_model_command", "instant /model switching"),
                  (b"tengu_fgts", "fine-grained tool streaming"),
                  (b"tengu_auto_background_agents", "background agent timeout"),
                  (b"tengu_plan_mode_interview_phase", "plan mode interview"),
                  (b"tengu_surreal_dali", "scheduled agents/cron"),
                ]

                memory_gates: list[Gate] = [
                  # (b"tengu_session_memory", "session memory"),  # auto-memory; pollutes unrelated convos
                  (b"tengu_pebble_leaf_prune", "message pruning"),
                  (b"tengu_herring_clock", "team memory directory"),
                  (b"tengu_passport_quail", "typed combined memory prompts"),
                  (b"tengu_paper_halyard", "memory dedup in nested dirs"),
                ]

                ux_gates: list[Gate] = [
                  (b"tengu_coral_fern", "grep hints in prompt"),
                  (b"tengu_kairos_brief", "brief output mode"),
                  (b"tengu_destructive_command_warning", "destructive command warnings"),
                  (b"tengu_amber_prism", "permission denial context"),
                  (b"tengu_hawthorn_steeple", "context windowing"),
                  (b"tengu_loud_sugary_rock", "Opus 4.7 terse output guidance"),
                  (b"tengu_verified_vs_assumed", "verified-vs-assumed reporting"),
                  (b"tengu_birch_compass", "/usage 'What's contributing' breakdown block"),
                  # tengu_pewter_brook (fullscreen TUI default) disabled — Ink fullscreen
                  # rendering drops memoized Text children in nested Box columns (/usage
                  # loses its "What's contributing..." bold header, big vertical gaps).
                  # Re-enable by setting `tui: "fullscreen"` in settings.json if desired.
                ]

                tool_gates: list[Gate] = [
                  (b"tengu_chrome_auto_enable", "auto-enable chrome devtools"),
                  (b"tengu_plum_vx3", "web search reranking"),
                  # (b"tengu_moth_copse", "relevant memory recall"),  # auto-recall; pollutes unrelated convos
                  (b"tengu_cork_m4q", "batch command processing"),
                  (b"tengu_harbor", "plugin marketplace"),
                  (b"tengu_harbor_permissions", "plugin permissions"),
                  (b"tengu_relay_chain_v1", "parallel command chaining guidance"),
                  (b"tengu_edit_minimalanchor_jrn", "Edit tool minimal-anchor instructions"),
                  (b"tengu_slate_reef", "Read tool clearer offset/limit docs"),
                  (b"tengu_otk_slot_v1", "output-token escalation for complex tasks"),
                  (b"tengu_onyx_basin_m1k", "subagent tool-result truncation"),
                  (b"tengu_sub_nomdrep_q7k", "block subagent report .md writes"),
                  (b"tengu_amber_sentinel", "Monitor tool for streaming bg scripts"),
                  (b"tengu_miraculo_the_bard", "skip penguin-mode startup prefetch"),
                  (b"tengu_noreread_q7m_velvet", "sharper 'wasted read' feedback"),
                ]

                flip_gates(core_gates + memory_gates + ux_gates + tool_gates)

                # --- Bump background agent timeout from 120s to 240s ---

                patch(
                  "background agent timeout",
                  rb'"tengu_auto_background_agents",![01]\)\)return 120000',
                  lambda m: m[0].replace(b"120000", b"240000"),
                )

                # --- Disable the claude-api bundled skill ---
                # Registered via vA({name:"claude-api",description:v4_,...}) at bundle-load
                # time. The description (v4_) is a ~200-token SDK/Bedrock usage matrix with
                # TRIGGER/SKIP rules that gets injected into every system prompt. We don't
                # write Anthropic SDK code in this environment, so cut it. Renamed from
                # `claude-developer-platform` in an earlier release — match on current name.

                patch(
                  "disable claude-api skill",
                  rb'(' + W + rb')\(\{name:"claude-api",description:',
                  lambda m: m[1] + b'({name:"claude-api",isEnabled:()=>!1,description:',
                )

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

                # --- grep/find/rg shim: delegate to absolute Nix store paths ---
                # claude-code ships a shell shim factory that emits bash functions
                # which redefine `grep`/`find`/`rg` to re-exec the claude binary
                # with argv[0]=ugrep/bfs/rg. In Bun "ant-native" builds this
                # dispatches to bundled native tools. The Deno repack drops those,
                # so invocations fail with `error: unknown option '-G'`. Replace the
                # factory's body so it emits bash that calls the real tools directly
                # via their Nix store paths.
                #
                # Anchor on (a) the (H,_,q=[]) signature — stable API contract with
                # the three call sites — and (b) the `\x60function ''${H} {` bash
                # header that this function MUST emit to do its job. Two other
                # functions share the signature so the bash header disambiguates.
                # Use brace-balanced parsing for the body end so internal restructures
                # (2.1.113→2.1.121 added windows-path branches and chained more lets)
                # don't break us.

                def scan_js_block(blob: bytes, pos: int) -> int:
                  """Return the offset just past the `}` closing the `{` at pos-1.
                  Tracks '...' / "..." / `...` (with ''${...} interpolations) so
                  braces inside strings don't count. Bun output has no comments or
                  regex literals in this region, so we don't track those."""
                  depth: int = 1
                  while pos < len(blob):
                    c: bytes = blob[pos:pos + 1]
                    if c == b"{":
                      depth += 1
                    elif c == b"}":
                      depth -= 1
                      if depth == 0:
                        return pos + 1
                    elif c in (b"'", b'"'):
                      pos += 1
                      while pos < len(blob) and blob[pos:pos + 1] != c:
                        pos += 2 if blob[pos:pos + 1] == b"\\" else 1
                    elif c == b"\x60":
                      pos += 1
                      while pos < len(blob) and blob[pos:pos + 1] != b"\x60":
                        if blob[pos:pos + 1] == b"\\":
                          pos += 2
                        elif blob[pos:pos + 2] == b"''${":
                          pos += 2
                          inner: int = 1
                          while pos < len(blob) and inner > 0:
                            ic: bytes = blob[pos:pos + 1]
                            if ic == b"{":
                              inner += 1
                            elif ic == b"}":
                              inner -= 1
                            pos += 1
                          continue
                        else:
                          pos += 1
                    pos += 1
                  sys.exit("a38 shim: unbalanced braces")


                # 2.1.139 added a fourth `K=[]` param (args that pass through to
                # `command ''${H}` rather than the shim). Allow either signature.
                a38_sig: bytes = rb"function (" + W + rb")\(H,_,q=\[\](?:,K=\[\])?\)\{"
                a38_match: re.Match[bytes] | None = None
                for cand in re.finditer(a38_sig, data):
                  if b"\x60function ''${H} {" in data[cand.end():cand.end() + 800]:
                    a38_match = cand
                    break

                if a38_match is None:
                  log("grep/find/rg shim: NOT FOUND")
                else:
                  fn_name: bytes = a38_match.group(1)
                  body_end: int = scan_js_block(data, a38_match.end())
                  a38_new: bytes = (
                    b"function " + fn_name + b"(H,_,q=[]){"
                    b'let K=q.length>0?\x60''${q.join(" ")} "$@"\x60:\'"$@"\';'
                    b'let P=({ugrep:"${getExe' pkgs.ugrep "ugrep"}",'
                    b'bfs:"${getExe pkgs.bfs}",'
                    b'rg:"${getExe pkgs.ripgrep}"})[_]||_;'
                    b"return\x60function ''${H} { "
                    b'if ! [ -x ''${P} ]; then command ''${H} "$@"; return; fi; '
                    b"''${P} ''${K}; }\x60}"
                  )
                  data = data[:a38_match.start()] + a38_new + data[body_end:]
                  log(f"grep/find/rg shim: replaced {fn_name.decode()}")

                # --- Bun runtime polyfill ---
                # Since 2.1.128 the bundle calls Bun.* APIs unguarded (Bun.stringWidth,
                # Bun.semver, Bun.hash, Bun.spawn, Bun.YAML, Bun.Transpiler, Bun.listen,
                # Bun.which, Bun.wrapAnsi, Bun.stripANSI, Bun.embeddedFiles, Bun.gc,
                # Bun.generateHeapSnapshot, Bun.JSONL, Bun.Terminal, Bun.version). Under
                # Deno these throw `ReferenceError: Bun is not defined` at first use
                # (Bun.stringWidth fires in a column-width helper during banner render).
                # Define globalThis.Bun upfront with Node-backed equivalents so bare
                # `Bun.X` lookups resolve.
                #
                # Bun.Terminal and Bun.JSONL are intentionally left absent: the bundle
                # already has fallback paths gated on `typeof Bun.Terminal<"u"` and
                # `Bun.JSONL?.parseChunk`, so leaving them undefined preserves the
                # built-in "running under Node?" degradation rather than half-emulating.

                bun_shim: bytes = rb"""(()=>{if(typeof globalThis.Bun!=="undefined")return;
                const sw=require("string-width"),sa=require("strip-ansi"),wa=require("wrap-ansi");
                const sv=require("semver"),ya=require("yaml");
                const cp=require("child_process"),fs=require("fs"),path=require("path");
                const crypto=require("crypto"),net=require("net");
                function bunHash(input){const buf=Buffer.isBuffer(input)?input:Buffer.from(typeof input==="string"?input:String(input));return crypto.createHash("sha1").update(buf).digest().readBigUInt64LE(0);}
                function bunSpawn(cmd,opts){opts=opts||{};const[bin,...args]=cmd;const stdio=["pipe","pipe",opts.stderr==="ignore"?"ignore":"pipe"];const child=cp.spawn(bin,args,{cwd:opts.cwd,env:opts.env||process.env,stdio,argv0:opts.argv0});const exited=new Promise(r=>child.on("exit",c=>r(c==null?1:c)));return{pid:child.pid,stdin:child.stdin,stdout:child.stdout,stderr:child.stderr,exitCode:null,killed:false,kill(s){try{child.kill(s)}catch{}this.killed=true},async wait(){return await exited},exited};}
                function bunListen(opts){const h=opts.socket||{};const server=net.createServer(s=>{s.data=undefined;if(h.open)try{h.open(s)}catch{}s.on("data",d=>h.data&&h.data(s,d));s.on("close",()=>h.close&&h.close(s));s.on("error",e=>h.error&&h.error(s,e));});server.listen(opts.port||0,opts.hostname||"127.0.0.1");return server;}
                class BunTranspiler{constructor(o){this.opts=o}transformSync(s){return s}}
                globalThis.Bun={version:"1.3.13",embeddedFiles:[],stringWidth:(s,o)=>sw(String(s||""),o),stripANSI:s=>sa(String(s||"")),wrapAnsi:(s,w,o)=>wa(String(s||""),w,o),semver:{satisfies:(a,b)=>sv.satisfies(a,b),order:(a,b)=>sv.compare(a,b)},hash:bunHash,which(cmd){const dirs=(process.env.PATH||"").split(path.delimiter);for(const d of dirs){const f=path.join(d,cmd);try{fs.accessSync(f,fs.constants.X_OK);return f;}catch{}}return null;},spawn:bunSpawn,listen:bunListen,YAML:{parse:s=>ya.parse(s),stringify:(o,r,i)=>ya.stringify(o,r,i)},Transpiler:BunTranspiler,generateHeapSnapshot:()=>new ArrayBuffer(0),gc:()=>{}};
                })();
                """

                data = bun_shim + data
                log("Bun runtime polyfill: prepended")

                Path(sys.argv[1]).write_bytes(data)
              '';

              claudeScript =
                pkgs.writeScriptBin "claude" # nu
                  ''
                    #!${getExe pkgs.nushell}

                    def detect-platform []: nothing -> string {
                      let arch = match ($nu.os-info.arch | str downcase) {
                        "x86_64" | "x64" | "amd64" => "x64"
                        "aarch64" | "arm64" => "arm64"
                        $arch => {
                          print --stderr $"(ansi red_bold)error:(ansi reset) unsupported arch: ($arch)"
                          exit 67
                        }
                      }

                      match ($nu.os-info.name | str downcase) {
                        "linux" => $"linux-($arch)"
                        "macos" | "darwin" => $"darwin-($arch)"
                        $os => {
                          print --stderr $"(ansi red_bold)error:(ansi reset) unsupported os: ($os)"
                          exit 67
                        }
                      }
                    }

                    def detect-version [--cache: directory, --rebuild]: nothing -> string {
                      let version_file = $cache | path join "latest-version"

                      match ($rebuild or (try { (date now) - (ls $version_file | get 0.modified) > 6hr })) {
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

                    def run-latest [--cache: directory, ...arguments] {
                      print --stderr $"(ansi yellow_bold)warn:(ansi reset) falling back to latest binary"

                      try {
                        let latest = ls --long ($cache | path join "claude-code-*")
                        | where { $in.type == "file" and ($in.mode | str substring 2..<3) == "x" }
                        | sort-by modified
                        | last
                        | get name
                        exec $latest ...$arguments
                      } catch {
                        print --stderr $"(ansi red_bold)error:(ansi reset) no binary found"
                        exit 67
                      }
                    }

                    def --wrapped main [--rebuild, ...arguments] {
                      let cache = $env
                      | get --optional "XDG_CACHE_HOME"
                      | default ($env.HOME | path join ".cache")
                      | path join "claude-code"

                      let version = detect-version --cache $cache --rebuild=($rebuild)
                      if ($version | is-empty) { run-latest --cache $cache ...$arguments }

                      let binary_path = $cache | path join $"claude-code-($version)"

                      if not ($binary_path | path exists) or $rebuild {
                        let archive = $"($binary_path).tar.gz"

                        if not ($archive | path exists) {
                          let platform = detect-platform

                          try {
                            http get --raw $"https://registry.npmjs.org/@anthropic-ai/claude-code-($platform)/-/claude-code-($platform)-($version).tgz"
                            | save --force --raw $archive
                          } catch {
                            print --stderr $"(ansi yellow_bold)warn:(ansi reset) failed to download tarball"
                            run-latest --cache $cache ...$arguments
                          }
                        }

                        let workdir = $cache | path join $"claude-code-($version)-workdir"
                        rm --recursive --force $workdir
                        mkdir $workdir

                        ^${getExe pkgs.gnutar} --extract --gzip --file $archive --directory $workdir
                        rm $archive

                        let cli = $workdir | path join "cli.cjs"
                        ^${getExe lift} ($workdir | path join "package" "claude") $cli
                        ^${getExe patch} $cli

                        r#'${
                          toJSON {
                            name = "claude-code-lifted";
                            type = "commonjs";
                            dependencies = {
                              ws = "^8";
                              undici = "^6";
                              node-fetch = "^3";
                              ajv = "^8";
                              ajv-formats = "^3";
                              yaml = "^2";
                              # Bun shim deps (see "Bun runtime polyfill" in patch script).
                              # Pinned to CJS-compatible majors: ESM-only releases
                              # (string-width@5+, strip-ansi@7+, wrap-ansi@8+) break
                              # require() inside cli.cjs.
                              string-width = "^4";
                              strip-ansi = "^6";
                              wrap-ansi = "^7";
                              semver = "^7";
                            };
                          }
                        }'# | save --force ($workdir | path join "package.json")

                        $env.DENO_DIR = ($workdir | path join ".deno")
                        (^"${getExe pkgs.deno}" install
                          --quiet
                          --node-modules-dir=auto
                          --entrypoint $cli)
                        (^"${getExe pkgs.deno}" compile
                          --quiet
                          --allow-all
                          --node-modules-dir=auto
                          --include ($workdir | path join "node_modules")
                          --output $binary_path
                          $cli)

                        rm --recursive --force $workdir
                      }

                      r#'${toJSON config.files.".claude/settings.json".value.env}'# | from json | load-env

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
                    --set ANTHROPIC_AUTH_TOKEN "dummy"
                '';
              })

              # claude-code sandbox deps.
            ]
            ++ optionals (!osConfig.nixpkgs.hostPlatform.isDarwin) [
              pkgs.socat
              pkgs.bubblewrap
            ];
        };
    };

  flake.modules.common.ai-extra =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      hjem.extraModule =
        { osConfig, ... }:
        let
          inherit (osConfig.age) secrets;
        in
        {
          packages = [
            inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.agentfs
            pkgs.codex
            pkgs.gemini-cli
            pkgs.qwen-code
          ];

          # Helper script for adding MCP servers.
          # Should probably use writeScriptBin but idc, I run it once.
          files."extra-ai-tools-setup" = {
            text = # nu
              ''
                #!/usr/bin/env nu
                try { claude mcp add -s user -t http context7 https://mcp.context7.com/mcp --header $"CONTEXT7_API_KEY: (cat ${secrets.context7Key.path})" }
                try { npx skills add JuliusBrussee/caveman --agent pi }
              '';
            executable = true;
          };
        };
    };
}
