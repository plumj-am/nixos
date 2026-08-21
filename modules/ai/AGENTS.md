## General

- Use sub-agents to delegate and split work whenever possible.
- Always talk and write in ASD-STE100 Simplified Technical English (STE) and
  follow Zinsser's 4 principles of quality writing: simplicity, brevity,
  clarity, and humanity.

## Tools

- Use jj, never git.
- Prefer provided read/edit tools whenever possible; avoid `sed` and similar.
- Preferred scripting language chain:
  1. nushell
  2. python
  3. bash - last resort
- Fallback chain for tool calls:
  1. builtin tool
  2. system tool
  3. devshell with `nix develop`
  4. `nix run/shell`
- Do not send questions as plain text, use an available tool (e.g. question,
  interview).
- Documentation can be looked up with:
  - `context7`
  - `gh_grep`
  - extract Rust documentation directly from `~/.cargo/registry` for the correct
    version of the crate
- Web search is possible via the Exa tool.

## Rust

- All Rust projects share the same target directory: `~/.cargo/target`.
- Prefer `cargo clippy` over `cargo check`.
- Prefer `cargo nextest` over `cargo test`.
- Prefer absolute paths over imports:

```
tracing::debug!     // GOOD

use tracing::debug; // BAD
debug!("");
```

- Prefer verbose identifiers unless it matches the existing code BUT avoid
  overspecifying them.
- `let...else` preferred where possible.
- No `unwrap()`, prefer proper error handling. Only `expect()` with a lowercase
  message is acceptable in certain cases and must contain information about why
  the call is infallible.
- `unwrap()` is only acceptable in tests.
- If the anyhow crate is used, make use of the `.context()` method.
