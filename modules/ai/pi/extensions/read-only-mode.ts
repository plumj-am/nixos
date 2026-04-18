/**
 * Read-Only Mode Extension
 *
 * Restricts the agent to read-only operations.
 * All tool calls allowed except edit/write.
 *
 * Usage:
 * - `/readonly` - Toggle read-only mode on/off
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { Key } from "@mariozechner/pi-tui"

const READ_ONLY_TOOLS = ["read", "bash", "grep", "find", "ls", "questionnaire"]
const NORMAL_TOOLS = ["read", "bash", "edit", "write"]

let readOnlyEnabled = false

// Write-like bash commands to block in read-only mode
const writeCommands = [
	/^rm\s/,
	/^mv\s/,
	/^cp\s/,
	/^mkdir\s/,
	/^touch\s/,
	/^chmod\s/,
	/^chown\s/,
	/^dd\s/,
	/^ln\s/,
	/^tee\s/,
	/^>|/,
	/^>\s/,
]

function isWriteCommand(command: string): boolean {
	return writeCommands.some((p) => p.test(command.trim()))
}

export default function readOnlyExtension(pi: ExtensionAPI): void {
	pi.registerCommand("readonly", {
		description: "Toggle read-only mode (no file modifications)",
		handler: async (_args, ctx) => {
			readOnlyEnabled = !readOnlyEnabled

			if (readOnlyEnabled) {
				pi.setActiveTools(READ_ONLY_TOOLS)
				ctx.ui.setStatus(
					"readonly",
					ctx.ui.theme.fg("warning", "⏸ readonly"),
				)
				ctx.ui.notify("Read-only mode enabled.")
			} else {
				pi.setActiveTools(NORMAL_TOOLS)
				ctx.ui.setStatus("readonly", undefined)
				ctx.ui.notify("Read-only mode disabled. Full access restored.")
			}
		},
	})

	pi.registerShortcut(Key.ctrlAlt("r"), {
		description: "Toggle read-only mode",
		handler: async (_args, ctx) => {
			readOnlyEnabled = !readOnlyEnabled

			if (readOnlyEnabled) {
				pi.setActiveTools(READ_ONLY_TOOLS)
				ctx.ui.setStatus(
					"readonly",
					ctx.ui.theme.fg("warning", "⏸ readonly"),
				)
				ctx.ui.notify("Read-only mode enabled.")
			} else {
				pi.setActiveTools(NORMAL_TOOLS)
				ctx.ui.setStatus("readonly", undefined)
				ctx.ui.notify("Read-only mode disabled. Full access restored.")
			}
		},
	})

	// Block edit/write tools AND write-like bash commands
	pi.on("tool_call", async (event) => {
		if (!readOnlyEnabled) return undefined

		// Block edit and write tools
		if (event.toolName === "edit" || event.toolName === "write") {
			return {
				block: true,
				reason: `Read-only mode: ${event.toolName} is disabled.`,
			}
		}

		// Block write-like bash commands
		if (event.toolName === "bash") {
			const cmd = (event.input.command as string) || ""
			if (isWriteCommand(cmd)) {
				return {
					block: true,
					reason: `Read-only mode: write commands blocked.`,
				}
			}
		}

		return undefined
	})

	// Reset on new session
	pi.on("session_start", async (_event, ctx) => {
		readOnlyEnabled = false
		ctx.ui.setStatus("readonly", undefined)
	})

	// Inject context before agent starts
	pi.on("before_agent_start", async (_event, ctx) => {
		if (!readOnlyEnabled) return undefined

		ctx.ui.setStatus(
			"readonly",
			ctx.ui.theme.fg("warning", "⏸ readonly"),
		)

		return {
			message: {
				customType: "readonly-mode-context",
				content: `[READ-ONLY MODE ACTIVE]
You are in read-only mode - file modifications are disabled.

Restrictions:
- You CANNOT: edit, write (file modifications are blocked)
- You can: read, bash, grep, find, ls, questionnaire, skills

Browse and analyze code freely, but do NOT try to make changes.`,
				display: false,
			},
		}
	})
}
