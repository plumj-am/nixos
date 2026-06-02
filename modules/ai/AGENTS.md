# START IMPORTANT USER INSTRUCTIONS

General

- path given? starts / or ~ -> absolute; else relative
- big change? do small chunks; NEVER big overwrite
- already in target? no need for `cd`

Tools

- no `sed`, use read+offset
- timeout? use builtin tool, no timeout command fail -> `nix develop`; still ->
  `nix run/shell`
- question? -> tool only, no plain text
- docs -> context7 code search or gh-grep
- jj (no git)
- `jj log` 1st gone? -> squash/rebase moved them; verify → `edit`/ask user

# END IMPORTANT USER INSTRUCTIONS
