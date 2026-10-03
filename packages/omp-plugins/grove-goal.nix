{
  perSystem =
    { pkgs, ... }:
    {
      # A single-file extension module. omp auto-discovers `.ts` files under the
      # agent directory's `extensions/`, so this is linked in as
      # `~/.omp/agent/extensions/theme.ts`.
      packages.omp-grove-goal =
        pkgs.writeText "omp-grove-goal.ts" # typescript
          ''
            /* Extended goal plugin for the grove monorepo */

            import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent"

            const COMMAND_NAME = "grove-goal"

            // Appended to the objective so goal mode keeps working until the repo is clean.
            const COMPLETION_REQUIREMENTS = [
            	"The goal is not complete until all of the following hold:",
            	'- "nix flake check" must pass.',
            	'- A commit message must be added with "jj commit -m <message>", following the repository commit guidelines, and "nix run .#trim" must pass on it.',
            ].join("\n")

            // Management verbs act on the running goal. They take no objective,
            // so they get no requirements.
            const MANAGEMENT_VERBS: Record<string, true> = {
            	show: true,
            	pause: true,
            	resume: true,
            	drop: true,
            	budget: true,
            }

            type ParsedCommand = { args: string }

            // Split `/grove-goal <args>` into its arguments.
            // Returns `null` when the text is not this command.
            function parseCommand(text: string): ParsedCommand | null {
            	const trimmed = text.trim()
            	if (!trimmed.startsWith("/")) {
            		return null
            	}

            	const body = trimmed.slice(1)
            	const separator = body.search(/[\s:]/)
            	if (separator === -1) {
            		return body === COMMAND_NAME ? { args: "" } : null
            	}
            	if (body.slice(0, separator) !== COMMAND_NAME) {
            		return null
            	}

            	return { args: body.slice(separator + 1).trim() }
            }

            // Rewrite `/grove-goal` into `/goal` plus the Grove completion gates.
            export default function groveGoal(pi: ExtensionAPI) {
            	pi.setLabel("Grove Goal")

            	pi.on("input", async (event, ctx) => {
            		const parsed = parseCommand(event.text)
            		if (!parsed) {
            			return
            		}

            		const [verb = ""] = parsed.args.split(/\s+/)
            		if (MANAGEMENT_VERBS[verb.toLowerCase()]) {
            			return { text: `/goal ''${parsed.args}` }
            		}

            		// `/goal set` reads its verb from the command text, so the whole text is the objective.
            		const prefix = verb.toLowerCase() === "set" ? "set " : ""
            		const objective = parsed.args.slice(prefix.length) ||
            			(await ctx.ui.input(
            				"Grove goal objective",
            				"What must the repo achieve?",
            			))?.trim()
            		if (!objective) {
            			return
            		}

            		return {
            			text: `/goal ''${prefix}''${objective}\n\n''${COMPLETION_REQUIREMENTS}`,
            		}
            	})

            	// Headless modes never run the input hook, so register the command there.
            	pi.registerCommand(COMMAND_NAME, {
            		description: "Goal mode with Grove completion gates",
            		handler: async (args, ctx) => {
            			const objective = args.trim() ||
            				(await ctx.ui.input(
            					"Grove goal objective",
            					"What must the repo achieve?",
            				))?.trim()
            			if (!objective) {
            				return
            			}

            			pi.sendUserMessage(`''${objective}\n\n''${COMPLETION_REQUIREMENTS}`, {
            				attribution: "user",
            			})
            		},
            	})
            }
          '';
    };
}
