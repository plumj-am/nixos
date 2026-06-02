/**
 * Pi Notify Extension
 *
 * Sends a Linux desktop notification via notify-send when Pi is ready for input.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { execFile } from "node:child_process"

function notify(title: string, body: string): void {
	execFile("notify-send", [title, body])
}

export default function (pi: ExtensionAPI) {
	pi.on("agent_end", async () => {
		notify("Pi", "Ready for input")
	})
}
