import { relative, resolve } from "node:path"
import { homedir } from "node:os"
import { execSync } from "node:child_process"
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent"
import {
	Editor,
	type EditorTheme,
	Key,
	matchesKey,
	truncateToWidth,
} from "@earendil-works/pi-tui"

const NIX_EVAL_CMD =
	"nix eval '.#nixosConfigurations.yuzu.config.ai.commands.bash.allow' --json 2>/dev/null"

const FALLBACK_ALLOWED: string[] = [
	"ag*",
	"awk*",
	"bat*",
	"cat*",
	"command*",
	"date*",
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
	"mktemp*",
	"nl*",
	"rg*",
	"sg*",
	"sort*",
	"tail*",
	"tree*",
	"true",
	"uniq*",
	"wait*",
	"wc*",
	"which*",
	"xargs*",
	"jj diff*",
	"jj log*",
	"jj show*",
	"jj st*",
	"jj status*",
	"git diff*",
	"git log*",
	"git show*",
	"git status*",
	"cargo build*",
	"cargo check*",
	"cargo clippy*",
	"cargo test*",
	"nix build*",
	"nix develop*",
	"nix eval*",
]

let allowedPatterns: string[] = [...FALLBACK_ALLOWED]
let autoDenyTimeoutEnabled = true
let autoDenyTimeoutMs = 30000

async function loadPatterns(): Promise<void> {
	for (let attempt = 1; attempt <= 3; attempt++) {
		try {
			const result = execSync(NIX_EVAL_CMD, {
				encoding: "utf-8",
				timeout: 15000,
				stdio: ["ignore", "pipe", "pipe"],
			})
			const parsed: unknown = JSON.parse(result.trim())
			if (
				Array.isArray(parsed) && parsed.length > 0 &&
				parsed.every((x) => typeof x === "string")
			) {
				allowedPatterns = parsed as string[]
				return
			}
		} catch {
			if (attempt < 3) {
				await new Promise((r) => setTimeout(r, attempt * 1000))
			}
		}
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

function splitRespectingQuotes(command: string, delimiter: string): string[] {
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
			!inSingleQuote && !inDoubleQuote && command.startsWith(delimiter, i)
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
			!inSingleQuote && !inDoubleQuote && parenDepth === 0 &&
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

function extractFirstLoop(
	command: string,
): { prefix: string; body: string; tail: string } | null {
	const loopRe = /\b(for\s+.*?|while\s+.*?);\s*do\b/g
	let m
	while ((m = loopRe.exec(command)) !== null) {
		const afterDo = m.index + m[0].length
		const rest = command.slice(afterDo)
		// Balanced scan for ; done (tracks nested for/while)
		let depth = 1
		let doneIdx = -1
		for (let i = 0; i < rest.length; i++) {
			if (rest.startsWith("; done", i) || rest.startsWith(";\tdone", i)) {
				depth--
				if (depth === 0) {
					doneIdx = i
					break
				}
				i += 5
			} else if (
				rest.startsWith("for ", i) || rest.startsWith("while ", i)
			) {
				depth++
			}
		}
		if (doneIdx === -1) continue
		const bodyEnd = afterDo + doneIdx
		const prefix = command.slice(0, m.index).trim()
		const body = command.slice(afterDo, bodyEnd).trim()
		let tail = command.slice(bodyEnd + 6).trim()
		tail = tail.replace(/^[|;&]+\s*/, "").trim()
		return { prefix, body, tail }
	}
	return null
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

function matchGlob(str: string, pattern: string): boolean {
	const re = pattern
		.replace(/[.+^${}()|[\]\\]/g, "\\$&")
		.replace(/\*\*/g, "{{GLOBSTAR}}")
		.replace(/\*/g, ".*")
		.replace(/\?/g, ".")
		.replace(/{{GLOBSTAR}}/g, ".*")
	return new RegExp(`^${re}$`, "s").test(str)
}

function isSafeCwdPrefix(command: string, cwd: string): string | null {
	const match = command.match(
		/^cd\s+['"]?([^'"]+)['"]?\s*&&\s*(.+)/,
	)
	if (!match) return null

	const cdPath = match[1].trim()
	const rest = match[2]

	const targetPath = cdPath.startsWith("~")
		? resolve(homedir(), cdPath.slice(cdPath.startsWith("~/") ? 2 : 1))
		: resolve(cwd, cdPath)

	const normCwd = resolve(cwd)
	const rel = relative(normCwd, targetPath)
	if (rel !== "" && rel.startsWith("..")) return null

	return rest
}

function checkCommand(
	command: string,
	cwd: string,
	singleCheck: (cmd: string) => boolean,
	mode: "every" | "some",
): boolean {
	const safeRest = isSafeCwdPrefix(command, cwd)
	const checkCmd = safeRest !== null ? safeRest : command

	const loopResult = extractFirstLoop(checkCmd)
	if (loopResult !== null) {
		const bodyOk = checkCommand(loopResult.body, cwd, singleCheck, mode)
		if (mode === "every" && !bodyOk) return false
		if (mode === "some" && bodyOk) return true
		// Check prefix and tail independently (don't rejoin — connectors differ)
		if (loopResult.prefix) {
			const prefixOk = checkCommand(
				loopResult.prefix,
				cwd,
				singleCheck,
				mode,
			)
			if (mode === "every" && !prefixOk) return false
			if (mode === "some" && prefixOk) return true
		}
		if (loopResult.tail) {
			return checkCommand(loopResult.tail, cwd, singleCheck, mode)
		}
		return true
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

function isAllowedSingle(command: string): boolean {
	// cd is always safe (just changes directory)
	if (
		command === "cd" || command.startsWith("cd ") ||
		command.startsWith("cd\t")
	) return true
	if (allowedPatterns.some((p) => matchGlob(command, p))) return true
	const stripped = stripAssignments(command)
	if (
		stripped && stripped !== command &&
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

function findBlockedSubcommand(command: string, cwd: string): string | null {
	const safeRest = isSafeCwdPrefix(command, cwd)
	const checkCmd = safeRest !== null ? safeRest : command

	// Recurse into compound structure same way as checkCommand, but return first failing sub-command
	const loopResult = extractFirstLoop(checkCmd)
	if (loopResult !== null) {
		if (loopResult.prefix) {
			const blocked = findBlockedSubcommand(loopResult.prefix, cwd)
			if (blocked) return blocked
		}
		const blocked = findBlockedSubcommand(loopResult.body, cwd)
		if (blocked) return blocked
		if (loopResult.tail) {
			return findBlockedSubcommand(loopResult.tail, cwd)
		}
		return null
	}

	for (
		const splitFn of [
			splitLines,
			splitSemicolons,
			splitChain,
			splitOr,
			splitPipes,
		]
	) {
		const parts = splitFn(checkCmd)
		if (parts.length > 1) {
			for (const part of parts) {
				const blocked = findBlockedSubcommand(part, cwd)
				if (blocked) return blocked
			}
			return null
		}
	}

	// Leaf: check if allowed
	if (!isAllowedSingle(checkCmd)) return checkCmd
	return null
}

function permissionPrompt(
	command: string,
	ctx: ExtensionContext,
): Promise<{ choice: "allow" | "block" | "timeout"; message?: string }> {
	return ctx.ui.custom<
		{ choice: "allow" | "block" | "timeout"; message?: string }
	>(
		(tui, theme, _kb, done) => {
			let optionIndex = 0
			let editMode = false
			let cachedLines: string[] | undefined
			const options = ["Yes", "No"]

			const editorTheme: EditorTheme = {
				borderColor: (s) => theme.fg("accent", s),
				selectList: {
					selectedPrefix: (t) => theme.fg("accent", t),
					selectedText: (t) => theme.fg("accent", t),
					description: (t) => theme.fg("muted", t),
					scrollInfo: (t) => theme.fg("dim", t),
					noMatch: (t) => theme.fg("warning", t),
				},
			}
			const editor = new Editor(tui, editorTheme)

			function refresh() {
				cachedLines = undefined
				tui.requestRender()
			}

			let timeoutId: ReturnType<typeof setTimeout> | undefined
			if (autoDenyTimeoutEnabled) {
				timeoutId = setTimeout(
					() => done({ choice: "timeout" }),
					autoDenyTimeoutMs,
				)
			}

			editor.onSubmit = () => {
				if (timeoutId) clearTimeout(timeoutId)
				done({
					choice: optionIndex === 0 ? "allow" : "block",
					message: editor.getText().trim() || undefined,
				})
			}

			return {
				render(width: number): string[] {
					if (cachedLines) return cachedLines

					const lines: string[] = []
					const add = (s: string) =>
						lines.push(truncateToWidth(s, width))

					add(theme.fg("accent", "─".repeat(width)))
					add(theme.fg("warning", " ⚠️  Command not in allowlist:"))
					lines.push("")
					for (const line of command.split("\n")) {
						add(`  ${theme.fg("text", line)}`)
					}
					lines.push("")
					add(theme.fg("text", " Allow?"))
					lines.push("")

					for (let i = 0; i < options.length; i++) {
						const selected = i === optionIndex
						const prefix = selected
							? theme.fg("accent", "> ")
							: "  "
						if (selected && editMode) {
							add(prefix + theme.fg("accent", `${options[i]} ✎`))
						} else if (selected) {
							add(prefix + theme.fg("accent", options[i]))
						} else {
							add(`  ${theme.fg("text", options[i])}`)
						}
					}

					if (editMode) {
						lines.push("")
						add(theme.fg("muted", " Message (optional):"))
						for (const line of editor.render(width - 2)) {
							add(` ${line}`)
						}
					}

					lines.push("")
					if (editMode) {
						add(theme.fg(
							"dim",
							" Enter to submit • Esc to go back",
						))
					} else {
						add(theme.fg(
							"dim",
							" ↑↓ navigate • Enter to confirm • Tab to add message • Esc to cancel",
						))
					}
					add(theme.fg("accent", "─".repeat(width)))

					cachedLines = lines
					return lines
				},
				invalidate: () => {
					cachedLines = undefined
				},
				handleInput(data: string) {
					if (editMode) {
						if (matchesKey(data, Key.escape)) {
							editMode = false
							editor.setText("")
							refresh()
							return
						}
						editor.handleInput(data)
						refresh()
						return
					}

					if (matchesKey(data, Key.up)) {
						optionIndex = Math.max(0, optionIndex - 1)
						refresh()
						return
					}
					if (matchesKey(data, Key.down)) {
						optionIndex = Math.min(
							options.length - 1,
							optionIndex + 1,
						)
						refresh()
						return
					}
					if (matchesKey(data, Key.tab)) {
						editMode = true
						refresh()
						return
					}
					if (matchesKey(data, Key.enter)) {
						if (timeoutId) clearTimeout(timeoutId)
						done({
							choice: optionIndex === 0 ? "allow" : "block",
							message: editor.getText().trim() || undefined,
						})
						return
					}
					if (matchesKey(data, Key.escape)) {
						if (timeoutId) clearTimeout(timeoutId)
						done({ choice: "block" })
						return
					}
				},
				cleanup: () => {
					if (timeoutId) {
						clearTimeout(timeoutId)
						timeoutId = undefined
					}
				},
			}
		},
	)
}

export default async function (pi: ExtensionAPI) {
	await loadPatterns()

	pi.registerCommand("perm-timeout", {
		description:
			"Toggle or set permission timeout auto-deny (e.g. /perm-timeout 10)",
		handler: async (args, ctx) => {
			const trimmed = args?.trim() ?? ""
			if (!trimmed) {
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

		if (isAllowed(command, ctx.cwd)) return undefined

		const blockedCmd = findBlockedSubcommand(command, ctx.cwd)
		const suggestion = blockedCmd
			? `At least part of the command "${blockedCmd}" is not in the allowlist. Try a different approach.`
			: "Command not in allowlist. Try a different approach."

		if (!ctx.hasUI) {
			return { block: true, reason: suggestion }
		}

		const result = await permissionPrompt(command, ctx)

		if (result.choice === "timeout") {
			const sec = Math.round(autoDenyTimeoutMs / 1000)
			return {
				block: true,
				reason: `${suggestion} (timed out after ${sec}s)`,
			}
		}

		if (result.choice === "allow") return undefined

		const reason = result.message
			? `The user denied this command with message: ${result.message}`
			: "Blocked by user"
		return { block: true, reason }
	})
}
