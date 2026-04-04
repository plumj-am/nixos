import QtQuick
import QtQuick.Layouts
import "../../common" as Common
import "../../services" as Services

RowLayout {
    id: root

    spacing: 8

    RowLayout {
        spacing: 8

        Text {
            text: Services.Network.networkType === 0 ? "\uf1eb" : "\ue7b8"
            font.family: Common.Theme.font.icons.family
            font.pixelSize: Common.Theme.font.sans.size
            color: Common.Theme.foreground
        }

        Text {
            text: Services.Network.activeInterface || "Disconnected"
            font.family: Common.Theme.font.sans.family
            font.pixelSize: Common.Theme.font.sans.size
            color: Common.Theme.foreground
            Layout.fillWidth: true
        }

        Text {
            text: "· " + (Services.Network.networkType === 0 ? "Wired" : "Wireless")
            font.family: Common.Theme.font.mono.family
            font.pixelSize: Common.Theme.font.mono.size
            color: Common.Theme.textMuted
        }
    }

    RowLayout {
        spacing: 8

        Text {
            text: "\uf063"
            font.family: Common.Theme.font.icons.family
            font.pixelSize: Common.Theme.font.mono.size
            color: Common.Theme.textMuted
        }

        Text {
            text: Services.Network.lanIPs.length > 0 ? Services.Network.lanIPs[0] : ""
            font.family: Common.Theme.font.mono.family
            font.pixelSize: Common.Theme.font.mono.size
            color: Common.Theme.textMuted
        }

        Text {
            text: "  \u2193 " + Utils.formatBytes(Services.Network.rateDown) + "/s"
            font.family: Common.Theme.font.mono.family
            font.pixelSize: Common.Theme.font.mono.size
            color: Common.Theme.textMuted
        }
    }
}
