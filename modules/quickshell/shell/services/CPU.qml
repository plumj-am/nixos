import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property var coreUsages: []
    property real overallUsage: 0.0
    property var prevStats: []
    property var topProcesses: []
    property var loadAvg: [0.0, 1.0, 15.0]
    property int numTopProcesses: 5

    Process {
        id: psProc
        running: false
        command: ["sh", "-c", "ps -eo pid,comm,%cpu --sort=-%cpu --no-headers | head -${numTopProcesses + 10}"]
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
                        const cpu = parseFloat(parts[2])
                        tp.push({pid: pid, comm: comm, cpu: cpu})
                    }
                }
                topProcesses = tp
            }
        }
    }

    Process {
        id: loadAvgProc
        running: false
        command: ["cat", "/proc/loadavg"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                const loads = line.split(/\s+/).map(s => parseFloat(s))
                if (loads.length >= 3) {
                    loadAvg = [loads[0], loads[1], loads[2]]
                }
            }
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoadFailed: function(error) {
            console.log("CPU Service: FileView load failed:", error)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateCpuUsage()
            psProc.running = true
            loadAvgProc.running = true
        }
    }

    function updateCpuUsage() {
        statFile.reload()
        const content = statFile.text()
        if (content === "") return

        const lines = content.split('\n')
        const currentStats = []

        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i].trim()
            if (line.startsWith('cpu')) {
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
                    currentStats.push({ total: total, idle: idle })
                }
            }
        }

        if (prevStats.length === currentStats.length && prevStats.length > 0) {
            let totalUsage = 0.0
            const coreUsagesTemp = []

            for (let j = 1; j < currentStats.length; ++j) {
                const current = currentStats[j]
                const prev = prevStats[j]
                const deltaTotal = current.total - prev.total
                const deltaIdle = current.idle - prev.idle
                let usage = (deltaTotal > 0) ? (deltaTotal - deltaIdle) / deltaTotal : 0.0
                usage = Math.min(Math.max(usage, 0.0), 1.0)
                coreUsagesTemp.push(usage)
            }

            const overallCurrent = currentStats[0]
            const overallPrev = prevStats[0]
            const overallDeltaTotal = overallCurrent.total - overallPrev.total
            const overallDeltaIdle = overallCurrent.idle - overallPrev.idle
            totalUsage = (overallDeltaTotal > 0) ? (overallDeltaTotal - overallDeltaIdle) / overallDeltaTotal : 0.0
            totalUsage = Math.min(Math.max(totalUsage, 0.0), 1.0)

            coreUsages = coreUsagesTemp
            overallUsage = totalUsage
        } else if (prevStats.length === 0) {
            prevStats = currentStats
        }

        prevStats = currentStats
    }
}
