import QtQuick
import "../../common"
import "../../services"

ResourceWidget {
    label: "C"
    valueText: (CPU.overallUsage >= 0 ? Math.round(CPU.overallUsage * 100) : 0) + "%"
    popupLines: [
        { text: "CPU", bold: true },
        { text: "Usage: " + Math.round(CPU.overallUsage * 100) + "%", mono: true },
        { text: "Load: " + (CPU.loadAvg[0] || 0).toFixed(2) + " " + (CPU.loadAvg[1] || 0).toFixed(2) + " " + (CPU.loadAvg[2] || 0).toFixed(2), mono: true, muted: true }
    ]
}
