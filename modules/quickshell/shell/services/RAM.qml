pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property real total: 0.0
    property real used: 0.0
    property real shared: 0.0
    property real buffers: 0.0
    property real cached: 0.0
    property real sreclaimable: 0.0
    property real free: 0.0
    property real available: 0.0
    property var topProcesses: []
    property int numTopProcesses: 5

    signal statsUpdated()

    Process {
        id: psProc
        running: false
        command: ["sh", "-c", `ps -eo pid,comm,%mem --sort=-%mem --no-headers | head -${numTopProcesses + 10}`]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.split('\n').filter(l => l.trim() !== '')
                let tp = []
                for (const line of lines) {
                    if (tp.length == numTopProcesses) break
                    const parts = line.trim().split(/\s+/)
                    if (parts.length === 3) {
                        const comm = parts[1]
                        if (comm === 'ps') continue
                        const pid = parseInt(parts[0])
                        const mem = parseFloat(parts[2])
                        tp.push({pid: pid, comm: comm, mem: mem})
                    }
                }
                topProcesses = tp
            }
        }
    }

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoadFailed: function(error) {
            console.log("RAM Service: FileView load failed:", error)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateRamStats()
            psProc.running = true
        }
    }

    function updateRamStats() {
        meminfoFile.reload()
        const content = meminfoFile.text()
        if (content === "") return

        const lines = content.split('\n')
        const stats = {}

        for (const line of lines) {
            const parts = line.split(/\s+/)
            if (parts.length >= 2) {
                const key = parts[0].slice(0, -1)
                const value = parseFloat(parts[1])
                stats[key] = value
            }
        }

        total = stats.MemTotal || 0.0
        free = stats.MemFree || 0.0
        buffers = stats.Buffers || 0.0
        cached = stats.Cached || 0.0
        shared = stats.Shmem || 0.0
        available = stats.MemAvailable || (free + buffers + cached)
        sreclaimable = stats.SReclaimable || 0.0
        used = Math.max(0, total - available)

        statsUpdated()
    }
}
