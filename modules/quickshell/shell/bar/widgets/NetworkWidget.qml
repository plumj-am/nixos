import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../common/widgets"
import "../../services"

Item {
    id: root

    implicitWidth: 60
    implicitHeight: 24

    RowLayout {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        height: 20

        Text {
            visible: Network.networkType === Types.networkWired
            text: "\uf0ac"
            font.family: "Hasklug Nerd Font Mono"
            font.pixelSize: 16
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: Network.networkType === Types.networkWireless
            text: "\uf1eb"
            font.family: "Hasklug Nerd Font Mono"
            font.pixelSize: 16
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: Network.networkType === Types.networkVirtual
            text: "\uf023"
            font.family: "Hasklug Nerd Font Mono"
            font.pixelSize: 16
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            width: 36
            text: formatRate(Network.rateDown)
            font.family: Config.data.theme.fontMono.family
            font.pixelSize: Config.data.theme.fontMono.size
            color: Theme.foreground
            horizontalAlignment: Text.AlignLeft
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    function formatRate(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec + "B"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + "K"
        return (bytesPerSec / 1024 / 1024).toFixed(1) + "M"
    }

    HoverPopup {
        anchors.centerIn: root
        hoverTarget: root
        anchorPosition: Types.stringToPosition(Config.data.bar.position)
        contentComponent: Component {
            ColumnLayout {
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Network"
                    font.family: Config.data.theme.font.family
                    font.pixelSize: Config.data.theme.font.size
                    font.bold: true
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Interface: " + Network.activeInterface
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Type: " + Types.networkToString(Network.networkType)
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Network.lanIPs.length > 0
                    text: "IP: " + Network.lanIPs[0]
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.textMuted
                }
            }
        }
    }
}
