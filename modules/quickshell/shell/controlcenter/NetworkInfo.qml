import QtQuick
import QtQuick.Layouts
import "../common" as Common
import "../services" as Services

ColumnLayout {
    id: root

    spacing: 4

    RowLayout {
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: Services.Network.activeInterface ? (Services.Network.networkType === 0 ? "\uf796" : "\uf1eb") : "\uf127"
                font.family: Common.Theme.font.icons.family
                font.pixelSize: Common.Theme.font.sans.size
                color: Common.Theme.foreground
            }
        }

        Text {
            text: Services.Network.activeInterface || "Disconnected"
            font.family: Common.Theme.font.sans.family
            font.pixelSize: Common.Theme.font.sans.size
            color: Common.Theme.foreground
        }

        Text {
            visible: Services.Network.activeInterface
            text: "· " + (Services.Network.networkType === 0 ? "Wired" : "Wireless")
            font.family: Common.Theme.font.mono.family
            font.pixelSize: Common.Theme.font.mono.size
            color: Common.Theme.textMuted
        }
    }

    RowLayout {
        visible: Services.Network.activeInterface
        spacing: 8

        Item {
            Layout.preferredWidth: 24
        }

        Text {
            visible: Services.Network.lanIPs.length > 0
            text: Services.Network.lanIPs[0]
            font.family: Common.Theme.font.mono.family
            font.pixelSize: Common.Theme.font.mono.size
            color: Common.Theme.textMuted
        }

        Text {
            visible: Services.Network.rateDown > 0
            text: "\u2193 " + Common.Utils.formatBytes(Services.Network.rateDown) + "/s"
            font.family: Common.Theme.font.mono.family
            font.pixelSize: Common.Theme.font.mono.size
            color: Common.Theme.textMuted
        }
    }
}
