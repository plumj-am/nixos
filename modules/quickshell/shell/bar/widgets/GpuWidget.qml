import QtQuick
import "../../common"
import "../../services"

ResourceWidget {
    label: "G"
    valueText: Math.round(GPU.overallUsage * 100) + "%"
    popupLines: GPU.memoryTotal > 0 ? [
        { text: "GPU", bold: true },
        { text: "Usage: " + Math.round(GPU.overallUsage * 100) + "%", mono: true },
        { text: "VRAM: " + GPU.memoryUsed.toFixed(1) + " / " + GPU.memoryTotal.toFixed(1) + " GB", mono: true, muted: true }
    ] : [
        { text: "GPU", bold: true },
        { text: "Usage: " + Math.round(GPU.overallUsage * 100) + "%", mono: true }
    ]
}
