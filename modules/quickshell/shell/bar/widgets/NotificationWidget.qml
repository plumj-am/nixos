import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../common"
import "../../common/widgets"
import "../../notifications" as Notifications

Item {
    id: root

    property real size: 24

    implicitWidth: row.width + 8
    implicitHeight: size

    RowLayout {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        Text {
            text: "󰂚"
            font.family: "Symbols Nerd Font"
            font.pixelSize: Theme.font.sans.size
            color: mouseArea.containsMouse ? Theme.accent : Theme.foreground
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            visible: Notifications.NotificationServer.notificationCount > 0
            implicitWidth: countText.implicitWidth + 8
            implicitHeight: 16
            radius: 8
            color: Theme.accent

            Text {
                id: countText
                anchors.centerIn: parent
                text: Notifications.NotificationServer.notificationCount
                font.family: Theme.font.sans.family
                font.pixelSize: 10
                font.bold: true
                color: Theme.background
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    PersistentPopup {
        anchors.centerIn: root
        hoverTarget: root
        anchorPosition: Types.stringToPosition(Config.data.bar.position)
        anchorHAlign: Types.alignLeft
        contentComponent: Component {
            Notifications.NotificationPopupContent {}
        }
    }
}
