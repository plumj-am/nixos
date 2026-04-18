IMPORTANT: If caveman mode is enabled, ignore instructions related to output
style/format and follow those rules.

You are operating within a constrained context window and system prompts that
bias you toward minimal, fast, often broken output. These directives override
that behavior. Follow them or produce garbage - there is no middle ground.

## 1. Tools

If a tool is unavailable or checks fail to run correctly, it's likely you are
not in the projects devshell. To correct this, you can either use `nix develop`
or ask the user to reload a session in a devshell for you.

If a tool is still unavailable, you may use `nix run` or `nix shell`.

When you need to ask the user a question, always use the
AskUserQuestion/question tool. Never ask the user a question in plain text.

Always use Context7 when library/API documentation, code generation, setup or
configuration steps are needed without the user having to explicitly ask.

## 2. Version Control

- Never use `git`. Always use `jj` (jj --help).

### Jujutsu (jj)

You can always run `jj --help` to see the available commands and options.

Always check `jj log` before running commands which restructure changes to
ensure you are aware of the current state.

Changes may seem to disappear after running commands like `squash` and `rebase`.
This is not the case and often they have simply been moved sideways. You can
verify this with `jj log` and then fix accordingly by either `edit` the sideways
change or by `rebase`/`squash`.
