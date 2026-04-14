import { homedir } from "node:path"
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

export const allowedExtraCwds: string[] = [
	"/tmp",
	"/tmp/",
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

export default function (pi: ExtensionAPI) {
	// Get cwd from extension context on first use
	let cwdCache: string | null = null

	function getCwd(): string {
		if (!cwdCache) {
			// Access cwd through pi's API
			cwdCache = process.cwd()
		}
		return cwdCache
	}

	function isSafeCwdPrefix(command: string, cwd: string): string | null {
		const match = command.match(
			/^cd\s+['"]?([^'"]+)['"]?\s*&&\s*(.+)/,
		)
		if (!match) return null

		const cdPath = match[1]
		const rest = match[2]

		// Resolve the cd target
		let targetPath: string
		if (cdPath.startsWith("/")) {
			targetPath = cdPath
		} else if (cdPath === "~" || cdPath.startsWith("~/")) {
			targetPath = homedir() + cdPath.slice(1)
		} else {
			targetPath = cwd + "/" + cdPath
		}

		// Normalize and check if it's cwd or a subdirectory
		const normalizedTarget = targetPath.replace(/\/$/, "")
		const normalizedCwd = cwd.replace(/\/$/, "")

		// Must be cwd or child of cwd
		if (
			normalizedTarget !== normalizedCwd &&
			!normalizedTarget.startsWith(normalizedCwd + "/")
		) {
			// Check extra allowed cwds
			const isExtraAllowed = allowedExtraCwds.some((allowed) => {
				const normAllowed = allowed.replace(/\/$/, "")
				return normalizedTarget === normAllowed ||
					normalizedTarget.startsWith(normAllowed + "/")
			})
			if (!isExtraAllowed) {
				return null
			}
		}

		return rest
	}

	function isAllowed(command: string): boolean {
		// Try stripping safe cwd prefix first
		const safeRest = isSafeCwdPrefix(command, getCwd())
		if (safeRest !== null) {
			return allowedPatterns.some((p) => p.test(safeRest))
		}
		return allowedPatterns.some((p) => p.test(command))
	}

	function isDangerous(command: string): boolean {
		// Try stripping safe cwd prefix first
		const safeRest = isSafeCwdPrefix(command, getCwd())
		const checkCmd = safeRest !== null ? safeRest : command
		return dangerousPatterns.some((p) => p.test(checkCmd))
	}

	pi.registerCommand("yolo", {
		description:
			"Toggle yolo mode (minimal restrictions, block only very bad commands)",
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
				ctx.ui.notify(
					"Yolo mode disabled. Normal restrictions restored.",
				)
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
				ctx.ui.notify(
					"Yolo mode disabled. Normal restrictions restored.",
				)
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
		cwdCache = null // Refresh cwd on new session
		ctx.ui.setStatus("yolo", undefined)
	})
}
