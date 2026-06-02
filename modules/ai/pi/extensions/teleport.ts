/**
 * Teleport Extension
 *
 * /teleport-to <dir>   — push current session to dir
 * /teleport-from <dir> — pull most recent session from dir into here
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { SessionManager } from "@mariozechner/pi-coding-agent"
import { existsSync } from "node:fs"
import { resolve } from "node:path"

export default function (pi: ExtensionAPI) {
	// ── push ──────────────────────────────────────────────────────
	pi.registerCommand("teleport-to", {
		description: "Push current session to <dir>",
		handler: async (args, ctx) => {
			const input = args.trim()
			if (!input) {
				ctx.ui.notify("Usage: /teleport-to <dir>", "info")
				return
			}

			const targetDir = resolve(input)
			if (!existsSync(targetDir)) {
				ctx.ui.notify(`✗ Directory not found: ${targetDir}`, "error")
				return
			}

			const sessionFile = ctx.sessionManager.getSessionFile()
			if (!sessionFile) {
				ctx.ui.notify("✗ Cannot teleport an in-memory session", "error")
				return
			}

			const oldCwd = ctx.cwd
			const forked = SessionManager.forkFrom(sessionFile, targetDir)
			const forkedFile = forked.getSessionFile()
			if (!forkedFile) {
				ctx.ui.notify("✗ Failed to fork session", "error")
				return
			}

			await ctx.switchSession(forkedFile, {
				withSession: async (ctx) => {
					ctx.ui.notify(` Teleported to ${targetDir}`, "info")
					await ctx.sendUserMessage(
						`[TELEPORT] Session teleported from \`${oldCwd}\` to \`${targetDir}\`. Working directory changed. Continue.`,
					)
				},
			})
		},
	})

	// ── pull ─────────────────────────────────────────────────────
	pi.registerCommand("teleport-from", {
		description: "Pull most recent session from <dir> into current dir",
		handler: async (args, ctx) => {
			const input = args.trim()
			if (!input) {
				ctx.ui.notify("Usage: /teleport-from <dir>", "info")
				return
			}

			const sourceDir = resolve(input)
			if (!existsSync(sourceDir)) {
				ctx.ui.notify(
					`✗ Source directory not found: ${sourceDir}`,
					"error",
				)
				return
			}

			const sessions = await SessionManager.list(sourceDir)
			if (sessions.length === 0) {
				ctx.ui.notify(`✗ No sessions found in ${sourceDir}`, "error")
				return
			}

			const labels = sessions.map((s) => {
				const date = s.created.toLocaleString()
				const name = s.name ?? s.firstMessage?.slice(0, 80) ?? "(empty)"
				return `${date} — ${name}`
			})
			const pick = await ctx.ui.select("Pick session to pull:", labels)
			if (!pick) return

			const sourceSessionFile = sessions[labels.indexOf(pick)].path

			const forked = SessionManager.forkFrom(sourceSessionFile, ctx.cwd)
			const forkedFile = forked.getSessionFile()
			if (!forkedFile) {
				ctx.ui.notify("✗ Failed to fork session", "error")
				return
			}

			await ctx.switchSession(forkedFile, {
				withSession: async (ctx) => {
					ctx.ui.notify(
						` Teleported session from ${sourceDir}`,
						"info",
					)
					await ctx.sendUserMessage(
						`[TELEPORT] Session teleported from \`${sourceDir}\` to \`${ctx.cwd}\`. Working directory changed. Continue.`,
					)
				},
			})
		},
	})
}
