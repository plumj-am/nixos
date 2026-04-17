import { exec } from "node:child_process"
import { promisify } from "node:util"
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"

const execAsync = promisify(exec)

async function readThemeMode(): Promise<"dark" | "light"> {
	try {
		const { stdout } = await execAsync(
			"cat /home/jam/nixos/modules/theme.json | jq -r .mode",
			{ timeout: 1000 },
		)
		return stdout.trim() === "dark" ? "dark" : "light"
	} catch {
		return "dark"
	}
}

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | null = null
	let currentTheme: "dark" | "light" | null = null

	pi.on("session_start", async (_event, ctx) => {
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