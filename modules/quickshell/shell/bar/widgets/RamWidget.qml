import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../common"
import "../../common/widgets"
import "../../services"

Item {
    id: root

    implicitWidth: row.width + 8
    implicitHeight: 24

    RowLayout {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        height: 20

        Text {
            text: "\uf1c0"
            font.family: "Hasklug Nerd Font Mono"
            font.pixelSize: 14
            color: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: Math.round(RAM.used / RAM.total * 100) + "%"
            font.family: Config.data.theme.fontMono.family
            font.pixelSize: Config.data.theme.fontMono.size
            color: Theme.foreground
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
                    text: "RAM"
                    font.family: Config.data.theme.font.family
                    font.pixelSize: Config.data.theme.font.size
                    font.bold: true
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Used: " + (RAM.used / 1024 / 1024).toFixed(1) + " GB"
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Total: " + (RAM.total / 1024 / 1024).toFixed(1) + " GB"
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.textMuted
                }
            }
        }
    }
}
