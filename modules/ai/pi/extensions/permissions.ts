import { matchesGlob, relative, resolve } from "node:path"
import { homedir } from "node:os"
import { appendFileSync, mkdirSync } from "node:fs"
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@mariozechner/pi-coding-agent"
import { Key } from "@mariozechner/pi-tui"

let autoDenyTimeoutEnabled = true
let autoDenyTimeoutMs = 30000

// Read-only allowlist patterns (strict mode)
export const allowedPatterns: string[] = [
	"ag*",
	"awk*",
	"bat*",
	"cat*",
	"command*",
	"echo*",
	"false",
	"fd*",
	"find*",
	"fzf*",
	"grep*",
	"head*",
	"hyperfine*",
	"less*",
	"ls*",
	"rg*",
	"sg*",
	"sort*",
	"tail*",
	"tree*",
	"true",
	"wait*",
	"wc*",
	"which*",
	"xargs*",

	"jj bookmark list*",
	"jj commit -m*",
	"jj commit --message*",
	"jj desc -m*",
	"jj desc --message*",
	"jj diff*",
	"jj evolog*",
	"jj file list*",
	"jj file search*",
	"jj file show*",
	"jj git colocation status*",
	"jj git remote list*",
	"jj git root*",
	"jj help*",
	"jj interdiff*",
	"jj log*",
	"jj new -m*",
	"jj new --message*",
	"jj op diff*",
	"jj op log*",
	"jj op show*",
	"jj operation diff*",
	"jj operation log*",
	"jj operation show*",
	"jj resolve --list*",
	"jj root*",
	"jj show*",
	"jj sparse list*",
	"jj st",
	"jj status",
	"jj tag list*",
	"jj util config-schema*",
	"jj version*",
	"jj workspace list*",
	"jj workspace root*",

	"git branch --list*",
	"git branch --show-current*",
	"git diff*",
	"git log*",
	"git status*",

	"cargo build*",
	"cargo check*",
	"cargo clippy*",
	"cargo fmt*",
	"cargo nextest*",
	"cargo test*",
	"cargo tree*",

	"curl http://localhost*",
	"curl -s http://localhost*",
	"curl -X GET http://localhost*",
	"curl -s -X GET http://localhost*",
	"curl -X POST http://localhost*",
	"curl -s -X POST http://localhost*",
	"curl -X PUT http://localhost*",
	"curl -s -X PUT http://localhost*",
	"curl -X DELETE http://localhost*",
	"curl -s -X DELETE http://localhost*",

	"nix*build*",
	"nix*eval*",
	"nix*flake check*",
	"nix*log*",

	"fj actions tasks*",
	"fj issue search*",
	"fj issue view*",
	"fj pr list*",
	"fj repo view*",
	"fj wiki contents*",
	"fj wiki view*",

	"fasm*",
	"node --check*",
	"npx tsc*",
]

// Forbidden path patterns (strict mode)
export const forbiddenPathPatterns: string[] = [
	"**/run/agenix",
	"**/.env",
	"**/.env.*",
	"**/.ssh/**",
	"**/.gnupg/**",
	"**/.aws/**",
	"**/.netrc",
	"**/.npmrc",
	"**/.pypirc",
	"**/.cargo/credentials",
	"**/.config/gcloud",
	"**/.config/azure",
	"**/.config/aws",
	"**/.kube/**",
	"**/.terraform.d",
	"**/.terragrunt-cache",
	"/etc/shadow",
	"/etc/sudoers",
	"/etc/passwd",
	"/etc/group",
	"/root/.ssh/**",
	"/root/.gnupg/**",
	"/home/*/.ssh/**",
	"/home/*/.gnupg/**",
	"**/kubeconfig",
	"**/vaulttoken",
	"**/vaultsecret",
	"**/GITHUB_TOKEN",
	"**/AWS_ACCESS_KEY",
	"**/AWS_SECRET_KEY",
	"*EDITOR*vim*.swp",
]

export const allowedExtraCwds: string[] = ["/tmp"]

const forbiddenPathPatternsLower: string[] = forbiddenPathPatterns.map((p) =>
	p.toLowerCase()
)

const PATH_EXTRACTOR = /['"]?([^\s'"&|;]+)['"]?/g

const BLOCKED_LOG_DIR = resolve(homedir(), ".local", "share", "pi")
const BLOCKED_LOG_PATH = resolve(BLOCKED_LOG_DIR, "blocked-commands.log")

function logBlockedCommand(
	command: string,
	cwd: string,
	reason: string,
): void {
	try {
		mkdirSync(BLOCKED_LOG_DIR, { recursive: true })
		const timestamp = new Date().toISOString()
		const entry =
			`[${timestamp}] BLOCKED\n  command: ${command}\n  cwd: ${cwd}\n  reason: ${reason}\n\n`
		appendFileSync(BLOCKED_LOG_PATH, entry)
	} catch {
		// silently ignore logging failures
	}
}

function updateTimeoutStatus(ctx: ExtensionContext): void {
	if (autoDenyTimeoutEnabled) {
		const sec = Math.round(autoDenyTimeoutMs / 1000)
		ctx.ui.setStatus(
			"perm-timeout",
			ctx.ui.theme.fg("warning", `⏱ ${sec}s`),
		)
	} else {
		ctx.ui.setStatus("perm-timeout", undefined)
	}
}

export default function (pi: ExtensionAPI) {
	function isSafeCwdPrefix(command: string, cwd: string): string | null {
		const match = command.match(
			/^cd\s+['"]?([^'"]+)['"]?\s*&&\s*(.+)/,
		)
		if (!match) return null

		const cdPath = match[1]
		const rest = match[2]

		const targetPath = cdPath.startsWith("~")
			? resolve(homedir(), cdPath.slice(cdPath.startsWith("~/") ? 2 : 1))
			: resolve(cwd, cdPath)

		const normCwd = resolve(cwd)
		const rel = relative(normCwd, targetPath)
		const isWithinCwd = rel === "" || !rel.startsWith("..")

		if (!isWithinCwd) {
			const isExtraAllowed = allowedExtraCwds.some((allowed) => {
				const normAllowed = resolve(allowed)
				const relExtra = relative(normAllowed, targetPath)
				return relExtra === "" || !relExtra.startsWith("..")
			})
			if (!isExtraAllowed) return null
		}

		return rest
	}

	function isForbiddenPath(command: string): string | null {
		PATH_EXTRACTOR.lastIndex = 0
		let pathMatch
		while ((pathMatch = PATH_EXTRACTOR.exec(command)) !== null) {
			const path = pathMatch[1]
			if (
				path.startsWith("http://") ||
				path.startsWith("https://") ||
				path.startsWith("--") ||
				path.startsWith("-")
			) {
				continue
			}
			const lowerPath = path.toLowerCase()
			for (let i = 0; i < forbiddenPathPatternsLower.length; i++) {
				if (matchesGlob(lowerPath, forbiddenPathPatternsLower[i])) {
					return path
				}
			}
		}
		return null
	}

	function splitRespectingQuotes(
		command: string,
		delimiter: string,
	): string[] {
		const parts: string[] = []
		let current = ""
		let inSingleQuote = false
		let inDoubleQuote = false

		for (let i = 0; i < command.length; i++) {
			const char = command[i]

			if (char === "\\") {
				current += char + (command[i + 1] ?? "")
				i++
				continue
			}

			if (char === "'" && !inDoubleQuote) {
				inSingleQuote = !inSingleQuote
			} else if (char === '"' && !inSingleQuote) {
				inDoubleQuote = !inDoubleQuote
			}

			if (
				!inSingleQuote &&
				!inDoubleQuote &&
				command.startsWith(delimiter, i)
			) {
				parts.push(current.trim())
				current = ""
				i += delimiter.length - 1
				continue
			}

			current += char
		}

		parts.push(current.trim())
		return parts.filter(Boolean)
	}

	function splitChain(command: string): string[] {
		return splitRespectingQuotes(command, "&&")
	}

	function splitOr(command: string): string[] {
		return splitRespectingQuotes(command, "||")
	}

	function splitSemicolons(command: string): string[] {
		return splitRespectingQuotes(command, ";")
	}

	function splitPipes(command: string): string[] {
		const parts: string[] = []
		let current = ""
		let inSingleQuote = false
		let inDoubleQuote = false

		for (let i = 0; i < command.length; i++) {
			const char = command[i]

			if (char === "\\") {
				current += char + (command[i + 1] ?? "")
				i++
				continue
			}

			if (char === "'" && !inDoubleQuote) {
				inSingleQuote = !inSingleQuote
			} else if (char === '"' && !inSingleQuote) {
				inDoubleQuote = !inDoubleQuote
			}

			if (!inSingleQuote && !inDoubleQuote && char === "|") {
				if (command[i + 1] === "|") {
					current += "||"
					i++
				} else {
					parts.push(current.trim())
					current = ""
				}
				continue
			}

			current += char
		}

		parts.push(current.trim())
		return parts.filter(Boolean)
	}

	function stripAssignments(command: string): string {
		let str = command.trim()
		while (true) {
			const m = str.match(
				/^([A-Za-z_][A-Za-z0-9_]*)=(?:\$\([^)]*\)|`[^`]*`|'[^']*'|"[^"]*"|[^\s'"`])+\s*/,
			)
			if (!m) break
			str = str.slice(m[0].length)
		}
		return str.trim()
	}

	function splitLines(command: string): string[] {
		const parts: string[] = []
		let current = ""
		let inSingleQuote = false
		let inDoubleQuote = false
		let parenDepth = 0

		for (let i = 0; i < command.length; i++) {
			const char = command[i]

			if (char === "\\") {
				current += char + (command[i + 1] ?? "")
				i++
				continue
			}

			if (char === "'" && !inDoubleQuote) {
				inSingleQuote = !inSingleQuote
			} else if (char === '"' && !inSingleQuote) {
				inDoubleQuote = !inDoubleQuote
			} else if (!inSingleQuote && !inDoubleQuote) {
				if (char === "$" && command[i + 1] === "(") {
					parenDepth++
				} else if (char === ")" && parenDepth > 0) {
					parenDepth--
				}
			}

			if (
				!inSingleQuote &&
				!inDoubleQuote &&
				parenDepth === 0 &&
				char === "\n"
			) {
				parts.push(current.trim())
				current = ""
				continue
			}

			current += char
		}

		parts.push(current.trim())
		return parts.filter(Boolean)
	}

	function extractLoopBody(command: string): string | null {
		const trimmed = command.trim()
		if (!trimmed.startsWith("for ") && !trimmed.startsWith("while ")) return null
		const doMatch = trimmed.match(/;\s*do\s/)
		if (!doMatch) return null
		const doneMatch = trimmed.match(/;\s*done\s*$/)
		if (!doneMatch) return null
		const bodyStart = doMatch.index! + doMatch[0].length
		const bodyEnd = trimmed.length - doneMatch[0].length
		return trimmed.slice(bodyStart, bodyEnd).trim()
	}

	function checkCommand(
		command: string,
		cwd: string,
		singleCheck: (cmd: string) => boolean,
		mode: "every" | "some",
	): boolean {
		const safeRest = isSafeCwdPrefix(command, cwd)
		const checkCmd = safeRest !== null ? safeRest : command

		const loopBody = extractLoopBody(checkCmd)
		if (loopBody !== null) {
			return checkCommand(loopBody, cwd, singleCheck, mode)
		}

		const lineParts = splitLines(checkCmd)
		if (lineParts.length > 1) {
			return lineParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const semiParts = splitSemicolons(checkCmd)
		if (semiParts.length > 1) {
			return semiParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const chainParts = splitChain(checkCmd)
		if (chainParts.length > 1) {
			return chainParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const orParts = splitOr(checkCmd)
		if (orParts.length > 1) {
			return orParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		const pipeParts = splitPipes(checkCmd)
		if (pipeParts.length > 1) {
			return pipeParts[mode]((part) =>
				checkCommand(part, cwd, singleCheck, mode)
			)
		}

		return singleCheck(checkCmd)
	}

	// Lightweight glob matcher for command strings (not file paths).
	// Unlike path.matchesGlob, * here matches anything including / and spaces.
	function matchGlob(str: string, pattern: string): boolean {
		const re = pattern
			.replace(/[.+^${}()|[\]\\]/g, "\\$&")
			.replace(/\*\*/g, "{{GLOBSTAR}}")
			.replace(/\*/g, ".*")
			.replace(/\?/g, ".")
			.replace(/{{GLOBSTAR}}/g, ".*")
		return new RegExp(`^${re}$`, "s").test(str)
	}

	function isAllowedSingle(command: string): boolean {
		if (allowedPatterns.some((p) => matchGlob(command, p))) return true
		const stripped = stripAssignments(command)
		if (
			stripped &&
			stripped !== command &&
			allowedPatterns.some((p) => matchGlob(stripped, p))
		) {
			return true
		}
		const subMatch = command.match(/\$\(([\s\S]*?)\)/) ||
			command.match(/`([\s\S]*?)`/)
		if (subMatch) return isAllowedSingle(subMatch[1])
		return false
	}

	function isAllowed(command: string, cwd: string): boolean {
		return checkCommand(command, cwd, isAllowedSingle, "every")
	}

	pi.registerCommand("perm-timeout", {
		description:
			"Toggle or set permission timeout auto-deny (e.g. /perm-timeout 10)",
		handler: async (args, ctx) => {
			const trimmed = args?.trim() ?? ""
			if (!trimmed) {
				// Toggle with current/default timeout
				autoDenyTimeoutEnabled = !autoDenyTimeoutEnabled
			} else if (trimmed === "off" || trimmed === "0") {
				autoDenyTimeoutEnabled = false
			} else {
				const sec = Number.parseInt(trimmed, 10)
				if (Number.isNaN(sec) || sec <= 0) {
					ctx.ui.notify(
						`Invalid timeout: "${trimmed}". Use seconds (e.g. 10) or "off"`,
						"error",
					)
					return
				}
				autoDenyTimeoutMs = sec * 1000
				autoDenyTimeoutEnabled = true
			}
			updateTimeoutStatus(ctx)
			const sec = Math.round(autoDenyTimeoutMs / 1000)
			ctx.ui.notify(
				autoDenyTimeoutEnabled
					? `Permission timeout enabled (${sec}s auto-deny)`
					: "Permission timeout disabled (wait forever)",
				"info",
			)
		},
	})

	pi.registerShortcut(Key.ctrlAlt("t"), {
		description: "Toggle permission timeout auto-deny",
		handler: async (ctx) => {
			autoDenyTimeoutEnabled = !autoDenyTimeoutEnabled
			updateTimeoutStatus(ctx)
			const sec = Math.round(autoDenyTimeoutMs / 1000)
			ctx.ui.notify(
				autoDenyTimeoutEnabled
					? `Permission timeout enabled (${sec}s auto-deny)`
					: "Permission timeout disabled (wait forever)",
				"info",
			)
		},
	})

	pi.on("session_start", async (_event, ctx) => {
		autoDenyTimeoutEnabled = true
		autoDenyTimeoutMs = 30000
		updateTimeoutStatus(ctx)
	})

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined

		const command = event.input.command as string

		// Check forbidden paths first (always enforced)
		const forbiddenPath = isForbiddenPath(command)
		if (forbiddenPath) {
			const reason = `Forbidden path: ${forbiddenPath}`
			logBlockedCommand(command, ctx.cwd, reason)
			return {
				block: true,
				reason,
			}
		}

		if (isAllowed(command, ctx.cwd)) return undefined

		if (!ctx.hasUI) {
			const reason = "Command not in allowlist (no UI)"
			logBlockedCommand(command, ctx.cwd, reason)
			return { block: true, reason }
		}

		const selectOptions = autoDenyTimeoutEnabled
			? { timeout: autoDenyTimeoutMs }
			: undefined
		const start = Date.now()

		const choice = await ctx.ui.select(
			`⚠️ Command not in allowlist:\n\n  ${command}\n\nAllow?`,
			["Yes", "No"],
			selectOptions,
		)

		if (choice === "Yes") {
			return undefined
		}

		if (choice === "No") {
			logBlockedCommand(command, ctx.cwd, "Blocked by user")
			return { block: true, reason: "Blocked by user" }
		}

		// choice === undefined: either timeout or user cancelled
		const elapsed = Date.now() - start
		const sec = Math.round(autoDenyTimeoutMs / 1000)
		const reason =
			autoDenyTimeoutEnabled && elapsed >= autoDenyTimeoutMs - 500
				? `Timed out after ${sec}s. You can try an alternative command`
				: "Blocked by user"
		logBlockedCommand(command, ctx.cwd, reason)
		return { block: true, reason }
	})
}
