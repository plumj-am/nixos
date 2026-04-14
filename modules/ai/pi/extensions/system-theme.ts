import { exec } from "node:child_process"
import { promisify } from "node:util"
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"

const execAsync = promisify(exec)

async function isDarkMode(): Promise<boolean> {
	try {
		const { stdout } = await execAsync(
			"cat /home/jam/nixos/modules/theme.json | jq .mode",
		)
		return stdout.trim() === "dark"
	} catch {
		return false
	}
}

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | null = null

	pi.on("session_start", async (_event, ctx) => {
		let currentTheme = (await isDarkMode()) ? "dark" : "light"
		ctx.ui.setTheme(currentTheme)

		intervalId = setInterval(async () => {
			const newTheme = (await isDarkMode()) ? "dark" : "light"
			if (newTheme !== currentTheme) {
				currentTheme = newTheme
				ctx.ui.setTheme(currentTheme)
			}
		}, 2000)
	})

	pi.on("session_shutdown", () => {
		if (intervalId) {
			clearInterval(intervalId)
			intervalId = null
		}
	})
}
