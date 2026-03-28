pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property string activeInterface: ""
    property int networkType: 0
    property real rateDown: 0.0
    property var lanIPs: []

    property var prevRx: 0

    FileView {
        id: rxBytesView
        path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/statistics/rx_bytes` : ""
        onLoadFailed: err => console.log("Network: rx_bytes load failed:", err)
    }

    Process {
        id: detectIfaceProc
        running: true
        command: ["sh", "-c", "iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}'); if [ -n \"$iface\" ] && [ -d \"/sys/class/net/$iface/wireless\" ]; then echo \"$iface w\"; elif [ -n \"$iface\" ]; then echo \"$iface e\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                if (parts.length >= 2) {
                    setActiveInterface(parts[0], parts[1] === 'w' ? 1 : 0)
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: detectIfaceProc.running = true
    }

    Process {
        id: lanIPProc
        running: false
        command: ["ip", "-json", "addr", "show", root.activeInterface]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (data && data.length > 0) {
                        lanIPs = (data[0].addr_info || []).map(i => i.local).filter(Boolean)
                    }
                } catch (e) {
                    lanIPs = []
                }
            }
        }
    }

    Timer {
        id: rateTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateRates()
    }

    Timer {
        interval: Config.data.network?.updateInterval ?? 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateInfo()
    }

    function setActiveInterface(name, type) {
        if (name === activeInterface && type === networkType) return
        activeInterface = name
        networkType = type
        prevRx = 0
        rateDown = 0
        lanIPProc.running = true
    }

    function updateRates() {
        if (!activeInterface) return
        rxBytesView.reload()
        const rx = parseInt(rxBytesView.text().trim()) || 0
        if (prevRx > 0) {
            const elapsed = rateTimer.interval / 1000
            rateDown = Math.max(0, rx - prevRx) / elapsed
        }
        prevRx = rx
    }

    function updateInfo() {
        if (activeInterface) lanIPProc.running = true
    }
}
