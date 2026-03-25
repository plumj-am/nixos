pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: root

    property var interfaces: []
    property string activeInterface: ""
    property int networkType: 0  // 0=wired, 1=wireless, 2=virtual

    property real rateUp: 0.0
    property real rateDown: 0.0
    property var lanIPs: []

    property var prevTx: 0
    property var prevRx: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateRates()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateInfo()
    }

    FileView {
        id: txBytesView
        path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/statistics/tx_bytes` : ""
        onLoadFailed: err => {}
    }

    FileView {
        id: rxBytesView
        path: root.activeInterface ? `/sys/class/net/${root.activeInterface}/statistics/rx_bytes` : ""
        onLoadFailed: err => {}
    }

    Process {
        id: listInterfacesProc
        running: true
        command: ["sh", "-c", "ls /sys/class/net | grep -v lo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n')
                const iface = lines.find(l => l.trim()) || ""
                if (iface && !activeInterface) {
                    setActiveInterface(iface.trim(), 0)
                }
                interfaces = lines.map(l => l.trim()).filter(Boolean)
            }
        }
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

    function setActiveInterface(name, type) {
        activeInterface = name
        networkType = type
        prevTx = 0
        prevRx = 0
        rateUp = 0
        rateDown = 0
        lanIPProc.running = true
    }

    function updateRates() {
        if (!activeInterface) return
        txBytesView.reload()
        rxBytesView.reload()
        const tx = parseInt(txBytesView.text().trim()) || 0
        const rx = parseInt(rxBytesView.text().trim()) || 0
        if (prevTx > 0 && prevRx > 0) {
            rateUp = Math.max(0, tx - prevTx)
            rateDown = Math.max(0, rx - prevRx)
        }
        prevTx = tx
        prevRx = rx
    }

    function updateInfo() {
        if (activeInterface) lanIPProc.running = true
    }
}
