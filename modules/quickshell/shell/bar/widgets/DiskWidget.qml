import QtQuick
import "../../common"
import "../../services"

ResourceWidget {
    label: "D"
    valueText: (Disk.total > 0 ? Math.round(Disk.used / Disk.total * 100) : 0) + "%"
    popupLines: [
        { text: "Disk", bold: true },
        { text: "Used: " + Disk.formatBytes(Disk.used), mono: true },
        { text: "Total: " + Disk.formatBytes(Disk.total), mono: true, muted: true }
    ]
}
