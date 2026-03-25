import QtQuick
import QtQuick.Layouts
import Quickshell
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
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        CPUIcon {
            visible: true
            color: Theme.foreground
            scale: 14
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (CPU.overallUsage >= 0 ? Math.round(CPU.overallUsage * 100) : 0) + "%"
            font.family: Config.data.theme.fontMono.family
            font.pixelSize: Config.data.theme.fontMono.size
            color: Theme.foreground
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
                    text: "CPU"
                    font.family: Config.data.theme.font.family
                    font.pixelSize: Config.data.theme.font.size
                    font.bold: true
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Usage: " + Math.round(CPU.overallUsage * 100) + "%"
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Load: " + CPU.loadAvg[0].toFixed(2) + " " + CPU.loadAvg[1].toFixed(2) + " " + CPU.loadAvg[2].toFixed(2)
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.textMuted
                }
            }
        }
    }
}
