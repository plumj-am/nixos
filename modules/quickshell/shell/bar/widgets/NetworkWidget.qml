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
            visible: Network.networkType === Types.networkWired || Network.networkType === Types.networkWireless
            text: Network.networkType === Types.networkWired ? "\uef44" : "\uf1eb"
            font.family: Theme.font.icons.family
            font.pixelSize: Theme.font.mono.size
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            width: 36
            text: Utils.formatBytes(Network.rateDown)
            font.family: Theme.font.mono.family
            font.pixelSize: Theme.font.mono.size
            color: Theme.foreground
            horizontalAlignment: Text.AlignLeft
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }
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
                    font.family: Theme.font.sans.family
                    font.pixelSize: Theme.font.sans.size
                    font.bold: true
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Interface: " + Network.activeInterface
                    font.family: Theme.font.mono.family
                    font.pixelSize: Theme.font.mono.size
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Type: " + Types.networkToString(Network.networkType)
                    font.family: Theme.font.mono.family
                    font.pixelSize: Theme.font.mono.size
                    color: Theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Network.lanIPs.length > 0
                    text: "IP: " + Network.lanIPs[0]
                    font.family: Theme.font.mono.family
                    font.pixelSize: Theme.font.mono.size
                    color: Theme.textMuted
                }
            }
        }
    }
}
