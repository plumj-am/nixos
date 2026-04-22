/**
 * TPS Status Extension
 *
 * Shows tokens-per-second (TPS) of the current model in the status bar
 * during assistant message streaming.
 *
 * Tracks text/thinking delta chunks and computes a running TPS average.
 * Final TPS is shown after the message completes.
 */

import type {
	ExtensionAPI,
	ExtensionContext,
} from "@mariozechner/pi-coding-agent"
import type { AssistantMessageEvent } from "@mariozechner/pi-ai"

interface TpsState {
	startTime: number
	chunkCount: number
	lastUpdate: number
}

let state: TpsState | null = null

function isDeltaEvent(event: AssistantMessageEvent): boolean {
	return event.type === "text_delta" || event.type === "thinking_delta"
}

function formatTps(tps: number): string {
	if (tps >= 1000) return `${(tps / 1000).toFixed(1)}k`
	if (tps >= 100) return `${Math.round(tps)}`
	return `${tps.toFixed(1)}`
}

function updateStatus(ctx: ExtensionContext) {
	if (!state) return
	const elapsed = (Date.now() - state.startTime) / 1000
	if (elapsed < 0.1) return
	const tps = state.chunkCount / elapsed
	const label = ctx.ui.theme.fg("accent", `${formatTps(tps)} tps`)
	ctx.ui.setStatus("tps", label)
}

function clearStatus(ctx: ExtensionContext) {
	ctx.ui.setStatus("tps", undefined)
}

export default function tpsStatusExtension(pi: ExtensionAPI): void {
	pi.on("message_start", async (event, _ctx) => {
		if (event.message.role !== "assistant") return
		state = {
			startTime: Date.now(),
			chunkCount: 0,
			lastUpdate: Date.now(),
		}
	})

	pi.on("message_update", async (event, ctx) => {
		if (!state) return
		const ame = event.assistantMessageEvent
		if (isDeltaEvent(ame)) {
			state.chunkCount++
			// throttle status updates to ~10Hz to avoid TUI flicker
			const now = Date.now()
			if (now - state.lastUpdate >= 100) {
				state.lastUpdate = now
				updateStatus(ctx)
			}
		}
	})

	pi.on("message_end", async (event, ctx) => {
		if (!state) return
		if (event.message.role !== "assistant") return

		const elapsed = (Date.now() - state.startTime) / 1000
		const usage = (event.message as any).usage
		const outputTokens = usage?.output ?? state.chunkCount
		const tps = elapsed > 0 ? outputTokens / elapsed : 0

		// print stats inline after message
		const dur = elapsed < 1
			? `${Math.round(elapsed * 1000)}ms`
			: `${elapsed.toFixed(1)}s`
		const statsLine = ctx.ui.theme.fg(
			"dim",
			`[${formatTps(tps)} tps · ${dur} · ${outputTokens} tok]`,
		)
		ctx.ui.notify(statsLine)

		const label = ctx.ui.theme.fg("success", `${formatTps(tps)} tps`)
		ctx.ui.setStatus("tps", label)

		state = null
	})

	// reset on session events
	pi.on("session_start", async (_event, ctx) => {
		state = null
		clearStatus(ctx)
	})

	pi.on("session_shutdown", async (_event, ctx) => {
		state = null
		clearStatus(ctx)
	})
}
