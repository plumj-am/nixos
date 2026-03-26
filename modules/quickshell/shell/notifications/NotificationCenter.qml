import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common" as Common
import "."

PanelWindow {
    id: root

    property bool isOpen: false

    visible: isOpen
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 500

    anchors {
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.namespace: "quickshell-notification-center"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    margins {
        top: Common.Config.data.bar.size + Common.Theme.margin.normal
        right: Common.Theme.margin.normal
    }

    function toggle() {
        isOpen = !isOpen
    }

    function open() {
        isOpen = true
    }

    function close() {
        isOpen = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.close()
    }

    Rectangle {
        id: centerBox
        anchors.fill: parent
        color: Common.Theme.background
        radius: Common.Theme.radius.normal
        border.color: Common.Theme.outline
        border.width: 1

        opacity: root.isOpen ? 1.0 : 0.0
        scale: root.isOpen ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Common.Theme.margin.normal
            spacing: Common.Theme.margin.normal

            RowLayout{
                Layout.fillWidth: true
                spacing: Common.Theme.margin.normal

                Text{
                    text: "Notifications"
                    color: Common.Theme.text
                    font.family: Common.Theme.font.sans.name
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                Rectangle{
                    visible: NotificationServer.notificationCount > 0
                    implicitWidth: clearText.implicitWidth + Common.Theme.padding.normal * 2
                    implicitHeight: 28
                    color: clearMouseArea.containsMouse ? Common.Theme.surfaceContainer : Common.Theme.surface
                    radius: Common.Theme.radius.small

                    Text{
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear All"
                        color: Common.Theme.accent
                        font.family: Common.Theme.font.sans.name
                        font.pixelSize: 12
                    }

                    MouseArea{
                        id: clearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationServer.dismissAll()
                    }
                }
            }

            ListView{
                id: notificationList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: NotificationServer.notificationHistory
                spacing: Common.Theme.margin.small

                delegate: NotificationItem{
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

            Text{
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: NotificationServer.notificationCount === 0
                text: "No notifications"
                color: Common.Theme.textMuted
                font.family: Common.Theme.font.sans.name
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text{
                Layout.fillWidth: true
                text: NotificationServer.notificationCount + " notification" + (NotificationServer.notificationCount !== 1 ? "s" : "")
                color: Common.Theme.textMuted
                font.family: Common.Theme.font.sans.name
                font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
                visible: NotificationServer.notificationCount > 0
            }
        }
    }

    Keys.onEscapePressed: root.close()
}
