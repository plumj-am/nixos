import QtQuick
import "../../common"
import "../../services"

ResourceWidget {
    label: "M"
    valueText: Math.round(RAM.used / RAM.total * 100) + "%"
    popupLines: [
        { text: "RAM", bold: true },
        { text: "Used: " + (RAM.used / 1024 / 1024).toFixed(1) + " GB", mono: true },
        { text: "Total: " + (RAM.total / 1024 / 1024).toFixed(1) + " GB", mono: true, muted: true }
    ]
}
