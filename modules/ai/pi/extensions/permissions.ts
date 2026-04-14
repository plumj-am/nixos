import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"

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

export default function (pi: ExtensionAPI) {
	function isAllowed(command: string): boolean {
		return allowedPatterns.some((p) => p.test(command))
	}

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined

		const command = event.input.command as string

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
}
