import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../notifications" as Notifications

Item {
    id: root

    property real size: 24
    property bool drawerOpen: false

    implicitWidth: row.width + 8
    implicitHeight: size

    signal clicked()

    RowLayout {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        Text {
            text: "󰂚"
            font.family: Theme.font.icons.family
            font.pixelSize: Theme.font.sans.size
            color: mouseArea.containsMouse || root.drawerOpen ? Theme.accent : Theme.foreground
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
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
