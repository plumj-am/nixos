import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../common/widgets"
import "../../common/icons"
import "../../services"

Item {
    id: root

    implicitWidth: row.width + 8
    implicitHeight: 24

    Row {
        id: row
        spacing: 4
        anchors.centerIn: parent

        NetworkWiredIcon {
            visible: Network.networkType === Types.networkWired
            color: Theme.foreground
            scale: 14
        }

        NetworkWirelessIcon {
            visible: Network.networkType === Types.networkWireless
            color: Theme.foreground
            scale: 14
            bars: 3
        }

        NetworkVirtualIcon {
            visible: Network.networkType === Types.networkVirtual
            color: Theme.foreground
            scale: 14
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: formatRate(Network.rateDown)
            font.family: Config.data.theme.fontMono.family
            font.pixelSize: Config.data.theme.fontMono.size
            color: Theme.foreground
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
