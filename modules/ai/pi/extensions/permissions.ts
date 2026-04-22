import { homedir, matchesGlob, relative, resolve } from "node:path"
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@mariozechner/pi-coding-agent"
import { Key } from "@mariozechner/pi-tui"

// Read-only allowlist patterns (strict mode)
export const allowedPatterns: string[] = [
	"ag*",
	"bat*",
	"cat*",
	"fd*",
	"find*",
	"fzf*",
	"grep*",
	"head*",
	"less*",
	"ls*",
	"rg*",
	"sg*",
	"sort*",
	"tail*",
	"tree*",
	"which*",
	"command*",

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

	"fj actions tasks*",
	"fj issue search*",
	"fj issue view*",
	"fj pr list*",
	"fj repo view*",
	"fj wiki contents*",
	"fj wiki view*",

	"npx tsc*",
	"node --check*",
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

	function splitChain(command: string): string[] {
		return command.split(/\s*&&\s*/).map((s) => s.trim()).filter(Boolean)
	}

	function splitPipes(command: string): string[] {
		return command.split(/\s*\|\s*/).map((s) => s.trim()).filter(Boolean)
	}

	function checkCommand(
		command: string,
		cwd: string,
		singleCheck: (cmd: string) => boolean,
		mode: "every" | "some",
	): boolean {
		const safeRest = isSafeCwdPrefix(command, cwd)
		const checkCmd = safeRest !== null ? safeRest : command

		const chainParts = splitChain(checkCmd)
		if (chainParts.length > 1) {
			return chainParts[mode]((part) => singleCheck(part))
		}

		const pipeParts = splitPipes(checkCmd)
		if (pipeParts.length > 1) {
			return pipeParts[mode]((part) => singleCheck(part))
		}

		return singleCheck(checkCmd)
	}

	const isAllowedSingle = (command: string): boolean =>
		allowedPatterns.some((p) => matchesGlob(command, p))

	function isAllowed(command: string, cwd: string): boolean {
		return checkCommand(command, cwd, isAllowedSingle, "every")
	}

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined

		const command = event.input.command as string

		// Check forbidden paths first (always enforced)
		const forbiddenPath = isForbiddenPath(command)
		if (forbiddenPath) {
			return {
				block: true,
				reason: `Forbidden path: ${forbiddenPath}`,
			}
		}

		if (isAllowed(command, ctx.cwd)) return undefined

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
}
