import QtQuick
import QtQuick.Layouts
import "../common" as Common
import "."

ColumnLayout {
    id: root

    spacing: Common.Theme.margin.normal
    Layout.fillWidth: true
    implicitHeight: Math.min(450, contentHeight)
    Layout.minimumWidth: 300

    property real contentHeight: headerRow.implicitHeight + notificationList.implicitHeight + footerText.implicitHeight + (Common.Theme.margin.normal * 3)

    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: Common.Theme.margin.normal

        Text {
            text: "Notifications"
            color: Common.Theme.text
            font.family: Common.Theme.font.sans.family
            font.pixelSize: 16
            font.weight: Font.Bold
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            visible: NotificationServer.notificationCount > 0
            implicitWidth: clearText.implicitWidth + Common.Theme.padding.normal * 2
            implicitHeight: 28
            color: clearMouseArea.containsMouse ? Common.Theme.surfaceContainer : Common.Theme.surface
            radius: Common.Theme.radius.small

            Text {
                id: clearText
                anchors.centerIn: parent
                text: "Clear All"
                color: Common.Theme.accent
                font.family: Common.Theme.font.sans.family
                font.pixelSize: 12
            }

            MouseArea {
                id: clearMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationServer.dismissAll()
            }
        }
    }

    ListView {
        id: notificationList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(350, notificationList.contentHeight)
        clip: true
        model: NotificationServer.notificationHistory
        spacing: Common.Theme.margin.small

        delegate: NotificationItem {
            width: notificationList.width
            notification: modelData
            maxWidth: width
            showActions: true
            showDismiss: true
            notificationIndex: index

            onDismissed: NotificationServer.dismiss(notificationIndex)
            onActionTriggered: function(action) { NotificationServer.invokeAction(notification, action) }
        }
    }

    Text {
        id: emptyText
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: NotificationServer.notificationCount === 0
        text: "No notifications"
        color: Common.Theme.textMuted
        font.family: Common.Theme.font.sans.family
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: footerText
        Layout.fillWidth: true
        text: NotificationServer.notificationCount + " notification" + (NotificationServer.notificationCount !== 1 ? "s" : "")
        color: Common.Theme.textMuted
        font.family: Common.Theme.font.sans.family
        font.pixelSize: 11
        horizontalAlignment: Text.AlignRight
        visible: NotificationServer.notificationCount > 0
    }
}
