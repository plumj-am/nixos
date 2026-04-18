import { readFile } from "node:fs/promises"
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"

async function readThemeMode(): Promise<"dark" | "light"> {
	try {
		const data = JSON.parse(
			await readFile("/home/jam/nixos/modules/theme.json", "utf-8"),
		)
		return data.mode === "dark" ? "dark" : "light"
	} catch {
		return "dark"
	}
}

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | null = null
	let currentTheme: "dark" | "light" | null = null

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return undefined

		if (intervalId) {
			clearInterval(intervalId)
			intervalId = null
		}

		const mode = await readThemeMode()
		currentTheme = mode
		ctx.ui.setTheme(mode)

		intervalId = setInterval(async () => {
			const mode = await readThemeMode()
			if (mode !== currentTheme) {
				currentTheme = mode
				ctx.ui.setTheme(mode)
			}
		}, 60000)
	})

	pi.on("session_shutdown", () => {
		if (intervalId) {
			clearInterval(intervalId)
			intervalId = null
		}
	})
}
