import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../../common"
import "../../common/widgets"
import "../../common/icons"
import "../../services"

Item {
    id: root

    visible: Battery.available
    implicitWidth: row.width + 8
    implicitHeight: 24

    RowLayout {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        BatteryIcon {
            id: icon
            size: 20
            iconColor: Theme.foreground
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: Config.data.battery?.showPercentage ?? true
            text: Math.round(Battery.percentage * 100) + "%"
            font.family: Config.data.theme.fontMono.family
            font.pixelSize: Config.data.theme.fontMono.size
            color: Battery.isCritical ? Theme.error : Theme.foreground
            Layout.alignment: Qt.AlignVCenter
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
                    text: Battery.isCharging ? "Charging" : (Battery.isPluggedIn ? "Plugged in" : "On battery")
                    font.family: Config.data.theme.font.family
                    font.pixelSize: Config.data.theme.font.size
                    font.bold: true
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(Battery.percentage * 100) + "%"
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.foreground
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Battery.energyRate > 0
                    text: Battery.energyRate.toFixed(1) + "W"
                    font.family: Config.data.theme.fontMono.family
                    font.pixelSize: Config.data.theme.fontMono.size
                    color: Theme.textMuted
                }
            }
        }
    }
}
