pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property real overallUsage: 0.0
    property var prevStats: ({})

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoadFailed: err => console.log("CPU: stat load failed:", err)
    }

    Timer {
        interval: Config.data.cpu?.updateInterval ?? 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateCpu()
    }

    function updateCpu() {
        statFile.reload()
        const content = statFile.text()
        if (!content) return
        const line = content.split('\n')[0].trim()
        const parts = line.split(/\s+/)
        if (parts.length >= 8) {
            const user = parseInt(parts[1])
            const nice = parseInt(parts[2])
            const system = parseInt(parts[3])
            const idle = parseInt(parts[4])
            const iowait = parseInt(parts[5])
            const irq = parseInt(parts[6])
            const softirq = parseInt(parts[7])
            const total = user + nice + system + idle + iowait + irq + softirq
            const current = { total: total, idle: idle }

            if (prevStats.total > 0) {
                const deltaTotal = current.total - prevStats.total
                const deltaIdle = current.idle - prevStats.idle
                let usage = (deltaTotal > 0) ? (deltaTotal - deltaIdle) / deltaTotal : 0.0
                overallUsage = Math.min(Math.max(usage, 0.0), 1.0)
            }

            prevStats = current
        }
    }
}
