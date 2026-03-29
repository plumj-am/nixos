import QtQuick
import "../../common"
import "../../services"

ResourceWidget {
    label: "\uf2db"
    valueText: (CPU.overallUsage >= 0 ? Math.round(CPU.overallUsage * 100) : 0) + "%"
    popupLines: [
        { text: "CPU", bold: true },
        { text: "Usage: " + Math.round(CPU.overallUsage * 100) + "%", mono: true }
    ]
}
