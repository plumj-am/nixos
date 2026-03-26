import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../common"
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
            font.pixelSize: Config.data.theme.fontSans.size
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
                font.family: Config.data.theme.fontSans.family
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
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleProcess.running = true
    }

    Process {
        id: toggleProcess
        command: ["qs", "ipc", "-p", "/home/jam/nixos/modules/quickshell/shell", "call", "notifications", "toggle"]
    }
}
