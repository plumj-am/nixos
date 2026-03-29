import QtQuick
import "../../common"
import "../../services"

ResourceWidget {
    label: "\uf0a0"
    valueText: (Disk.total > 0 ? Math.round(Disk.used / Disk.total * 100) : 0) + "%"
    popupLines: [
        { text: "Disk", bold: true },
        { text: "Used: " + Utils.formatBytes(Disk.used), mono: true },
        { text: "Total: " + Utils.formatBytes(Disk.total), mono: true, muted: true }
    ]
}
