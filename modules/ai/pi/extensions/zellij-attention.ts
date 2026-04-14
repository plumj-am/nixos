import { exec } from "node:child_process"
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"

export default function (pi: ExtensionAPI) {
	pi.on("agent_start", async () => {
		exec(
			`zellij pipe --name zellij-attention::waiting::${process.env.ZELLIJ_PANE_ID}`,
		)
	})
	pi.on("agent_end", async () => {
		exec(
			`zellij pipe --name zellij-attention::completed::${process.env.ZELLIJ_PANE_ID}`,
		)
	})
}
