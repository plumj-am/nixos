pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property real overallUsage: 0.0
    property real memoryUsed: 0.0
    property real memoryTotal: 0.0

    Process {
        id: gpuProc
        running: false
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                const parts = text.split(",").map(s => s.trim())
                if (parts.length >= 3) {
                    overallUsage = parseFloat(parts[0]) / 100.0
                    memoryUsed = parseFloat(parts[1]) / 1024
                    memoryTotal = parseFloat(parts[2]) / 1024
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: gpuProc.running = true
    }
}
