import QtQuick
import QtQuick.Layouts
import "../common" as Common
import "."

Rectangle {
    id: root

    property var notification: null
    property int timeout: notification?.expireTimeout > 0 ? notification.expireTimeout * 1000 : 5000
    property bool autoDismiss: true

    signal dismissed()
    signal expired()
    signal actionTriggered(var action)

    implicitWidth: 300
    implicitHeight: notificationItem.implicitHeight
    width: implicitWidth
    height: implicitHeight
    color: "transparent"

    property bool isEntering: true
    property bool isExiting: false

    scale: isEntering ? 0.9 : 1.0
    opacity: isExiting ? 0.0 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: {
        isEntering = false
        if (autoDismiss && timeout > 0) {
            dismissTimer.start()
        }
    }

    Timer {
        id: dismissTimer
        interval: root.timeout
        onTriggered: root.expire()
    }

    function dismiss() {
        isExiting = true
        exitAnimationTimer.dismissMode = true
        exitAnimationTimer.start()
    }

    function expire() {
        isExiting = true
        exitAnimationTimer.dismissMode = false
        exitAnimationTimer.start()
    }

    Timer {
        id: exitAnimationTimer
        property bool dismissMode: false
        interval: 200
        onTriggered: dismissMode ? root.dismissed() : root.expired()
    }

    NotificationItem {
        id: notificationItem
        anchors.fill: parent
        notification: root.notification
        showActions: true
        showDismiss: true

        onDismissed: root.dismiss()
        onActionTriggered: (action) => {
            root.actionTriggered(action)
            root.dismiss()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: dismissTimer.stop()
        onExited: {
            if (autoDismiss && timeout > 0) {
                dismissTimer.interval = 2000
                dismissTimer.start()
            }
        }
    }
}
