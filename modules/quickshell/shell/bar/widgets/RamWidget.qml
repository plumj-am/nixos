import QtQuick
import "../../common"
import "../../services"

ResourceWidget {
    label: "\uefc5"
    valueText: (RAM.total > 0 ? Math.round(RAM.used / RAM.total * 100) : 0) + "%"
    popupLines: [
        { text: "RAM", bold: true },
        { text: "Used: " + (RAM.used / 1024 / 1024).toFixed(1) + " GB", mono: true },
        { text: "Total: " + (RAM.total / 1024 / 1024).toFixed(1) + " GB", mono: true, muted: true }
    ]
}
