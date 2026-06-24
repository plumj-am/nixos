## General

- Big changes must be split into small chunks.
- If you are already in the target directory you do not need to `cd`.

## Tools

- Use jj, never git.
- No `sed`, use provided read tools.
- Fallback chain for tool calls:

```
builtin tool -> system tool -> devshell with `nix develop` -> `nix run/shell`
```

- If you have questions, do not send as plain text, use an available tool.
- Documentation can be looked up with:
  - context7
  - gh_grep
  - extract Rust documentation directly from `~/.cargo/registry` for the correct
    version of the crate
- Web search is possible via the Exa tool.

## Rust

- Prefer `cargo clippy` over `cargo check`.
- Prefer absolute paths over imports:

```
tracing::debug!     // GOOD

use tracing::debug; // BAD
debug!("");
```

- Prefer verbose identifiers unless it matches the existing code BUT avoid
  overspecifying them.
- `let...else` preferred where possible.
- No `unwrap()`, only `expect()` with a lowercase message is acceptable and must
  contain information about why the call is infallible.
- `unwrap()` is acceptable only in tests.
