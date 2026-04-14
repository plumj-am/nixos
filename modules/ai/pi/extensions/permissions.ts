import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { Key } from "@mariozechner/pi-tui"

// Read-only allowlist patterns (strict mode)
export const allowedPatterns: RegExp[] = [
	/^ag /,
	/^bat /,
	/^cat /,
	/^fd /,
	/^find /,
	/^fzf /,
	/^grep /,
	/^head /,
	/^less /,
	/^ls /,
	/^rg /,
	/^sg /,
	/^tail /,
	/^tree /,

	/^jj bookmark list /,
	/^jj commit -m /,
	/^jj commit --message /,
	/^jj desc -m /,
	/^jj desc --message /,
	/^jj diff /,
	/^jj evolog /,
	/^jj file list /,
	/^jj file search /,
	/^jj file show /,
	/^jj git colocation status /,
	/^jj git remote list /,
	/^jj git root /,
	/^jj help /,
	/^jj interdiff /,
	/^jj log /,
	/^jj new -m /,
	/^jj new --message /,
	/^jj op diff /,
	/^jj op log /,
	/^jj op show /,
	/^jj operation diff /,
	/^jj operation log /,
	/^jj operation show /,
	/^jj resolve --list/,
	/^jj root /,
	/^jj show /,
	/^jj sparse list /,
	/^jj st$/,
	/^jj status$/,
	/^jj tag list /,
	/^jj util config-schema/,
	/^jj version/,
	/^jj workspace list /,
	/^jj workspace root /,

	/^git branch --list/,
	/^git branch --show-current/,
	/^git diff /,
	/^git log /,
	/^git status /,

	/^cargo check /,
	/^cargo clippy /,
	/^cargo fmt /,
	/^cargo nextest /,
	/^cargo test /,
	/^cargo tree /,

	/^curl http:\/\/localhost/,
	/^curl -s http:\/\/localhost/,
	/^curl -X GET http:\/\/localhost/,
	/^curl -s -X GET http:\/\/localhost/,
	/^curl -X POST http:\/\/localhost/,
	/^curl -s -X POST http:\/\/localhost/,
	/^curl -X PUT http:\/\/localhost/,
	/^curl -s -X PUT http:\/\/localhost/,
	/^curl -X DELETE http:\/\/localhost/,
	/^curl -s -X DELETE http:\/\/localhost/,

	/^fj actions tasks /,
	/^fj issue search /,
	/^fj issue view /,
	/^fj pr list /,
	/^fj repo view /,
	/^fj wiki contents /,
	/^fj wiki view /,
]

// Yolo mode: block only truly dangerous commands
export const dangerousPatterns: RegExp[] = [
	/^rm\s+-rf\s+\//,
	/^rm\s+-rf\s+\/\s*$/,
	/^dd\s+if=/,
	/^mkfs\./,
	/^ddrescue/,
	/:\s*>;*\s*\/dev\/sd/,
	/^shred/,
	/^mke2fs/,
	/^format\s+(drive|disk|usb|floppy)/i,
	/^fdisk\s+\/dev\/sd/,
	/^parted.*--fix-table/i,
	/rm\s+-[rf]+\s+(['"]|\/?)(home|root|etc|usr|var|sys|proc|opt|boot|dev)\1/i,
]

let yoloModeEnabled = false

function isDangerous(command: string): boolean {
	return dangerousPatterns.some((p) => p.test(command))
}

export default function (pi: ExtensionAPI) {
	function isAllowed(command: string): boolean {
		return allowedPatterns.some((p) => p.test(command))
	}

	pi.registerCommand("yolo", {
		description: "Toggle yolo mode (minimal restrictions, block only very bad commands)",
		handler: async (_args, ctx) => {
			yoloModeEnabled = !yoloModeEnabled

			if (yoloModeEnabled) {
				ctx.ui.notify(
					"Yolo mode enabled. Only truly dangerous commands blocked.",
				)
				ctx.ui.setStatus(
					"yolo",
					ctx.ui.theme.fg("warning", "⚡ yolo"),
				)
			} else {
				ctx.ui.notify("Yolo mode disabled. Normal restrictions restored.")
				ctx.ui.setStatus("yolo", undefined)
			}
		},
	})

	pi.registerShortcut(Key.ctrlAlt("y"), {
		description: "Toggle yolo mode",
		handler: async (_args, ctx) => {
			yoloModeEnabled = !yoloModeEnabled

			if (yoloModeEnabled) {
				ctx.ui.notify(
					"Yolo mode enabled. Only truly dangerous commands blocked.",
				)
				ctx.ui.setStatus(
					"yolo",
					ctx.ui.theme.fg("warning", "⚡ yolo"),
				)
			} else {
				ctx.ui.notify("Yolo mode disabled. Normal restrictions restored.")
				ctx.ui.setStatus("yolo", undefined)
			}
		},
	})

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined

		const command = event.input.command as string

		// Yolo mode: block only dangerous commands
		if (yoloModeEnabled) {
			if (isDangerous(command)) {
				return {
					block: true,
					reason: `Yolo mode blocked dangerous command: ${command}`,
				}
			}
			return undefined
		}

		if (isAllowed(command)) return undefined

		if (!ctx.hasUI) {
			return { block: true, reason: "Command not in allowlist (no UI)" }
		}

		const choice = await ctx.ui.select(
			`⚠️ Command not in allowlist:\n\n  ${command}\n\nAllow?`,
			["Yes", "No"],
		)

		if (choice !== "Yes") {
			return { block: true, reason: "Blocked by user" }
		}

		return undefined
	})

	// Reset yolo mode on new session
	pi.on("session_start", async (_event, ctx) => {
		yoloModeEnabled = false
		ctx.ui.setStatus("yolo", undefined)
	})
}
