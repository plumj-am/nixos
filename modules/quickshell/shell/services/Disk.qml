pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property real used: 0.0
    property real total: 0.0
    property string mountPoint: "/root"

    Process {
        id: dfProc
        running: false
        command: ["sh", "-c", "df -B1 " + mountPoint + " | tail -1 | awk '{print $3,$2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                if (parts.length >= 2) {
                    used = parseFloat(parts[0])
                    total = parseFloat(parts[1])
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) console.log("Disk: df command failed:", code)
        }
    }

    Timer {
        interval: Config.data.disk?.updateInterval ?? 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: dfProc.running = true
    }
}
