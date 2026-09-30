{
  perSystem =
    { pkgs, ... }:
    {
      # A single-file extension module. omp auto-discovers `.ts` files under the
      # agent directory's `extensions/`, so this is linked in as
      # `~/.omp/agent/extensions/theme.ts`.
      packages.omp-theme =
        pkgs.writeText "omp-theme.ts" # typescript
          ''
            /* Keep the omp theme in sync with the system theme. */

            import { readFile } from "node:fs/promises"

            const THEME_STATE = process.env.OMP_SYSTEM_THEME_STATE ?? "/etc/theme.json"

            const POLL_INTERVAL_MS = 60_000

            type Mode = "dark" | "light"

            interface ThemeUi {
              notify: (message: string, level: string) => void
              setTheme: (name: string) => Promise<{ success: boolean; error?: string }>
            }

            interface SessionContext {
              hasUI: boolean
              ui: ThemeUi
              setInterval: (callback: () => void, ms: number) => unknown
              clearTimer: (timer: unknown) => void
            }

            interface ExtensionApi {
              on: (
                event: "session_start" | "session_shutdown",
                handler: (event: unknown, ctx: SessionContext) => unknown,
              ) => void
            }

            async function readMode(): Promise<Mode | null> {
              try {
                const state: unknown = JSON.parse(await readFile(THEME_STATE, "utf-8"))
                if (state && typeof state === "object" && "mode" in state) {
                  const mode: unknown = state.mode
                  return mode === "dark" || mode === "light" ? mode : null
                }
                return null
              } catch {
                return null
              }
            }

            export default function systemTheme(pi: ExtensionApi): void {
              let timer: unknown = null
              let applied: Mode | null = null

              pi.on("session_start", async (_event, ctx) => {
                if (timer !== null) {
                  ctx.clearTimer(timer)
                  timer = null
                }
                // Headless, RPC and ACP sessions cannot switch the theme.
                if (!ctx.hasUI) return

                const sync = async () => {
                  const mode = await readMode()
                  if (mode === null || mode === applied) return

                  const result = await ctx.ui.setTheme(mode)
                  if (result.success) {
                    applied = mode
                  } else {
                    ctx.ui.notify(`system theme: ''${result.error ?? "theme switch failed"}`, "error")
                  }
                }

                await sync()
                timer = ctx.setInterval(() => void sync(), POLL_INTERVAL_MS)
              })

              pi.on("session_shutdown", (_event, ctx) => {
                if (timer === null) return
                ctx.clearTimer(timer)
                timer = null
              })
            }
          '';
    };
}
