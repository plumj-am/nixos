import QtQuick
import QtQuick.Layouts
import "../common" as Common
import "."

Rectangle {
    id: root

    property var notification: null
    property int timeout: notification?.expireTimeout > 0 ? notification.expireTimeout * 1000 : 8000
    property bool autoDismiss: true
    property bool skipEntryAnimation: false

    signal dismissed
    signal expired
    signal actionTriggered(var action)
    signal entryComplete

    implicitWidth: 300
    implicitHeight: notificationItem.implicitHeight
    width: implicitWidth
    height: implicitHeight
    color: "transparent"

    property bool hasEntered: skipEntryAnimation
    property bool isEntering: !hasEntered
    property bool isExiting: false

    scale: isEntering ? 0.9 : 1.0
    opacity: isExiting ? 0.0 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
            onRunningChanged: {
                if (!running && !isEntering) {
                    root.entryComplete();
                }
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        hasEntered = true;
        if (skipEntryAnimation) {
            root.entryComplete();
        }
        if (autoDismiss && timeout > 0) {
            dismissTimer.start();
        }
    }

    Timer {
        id: dismissTimer
        interval: root.timeout
        onTriggered: root.expire()
    }

    function dismiss() {
        isExiting = true;
        exitAnimationTimer.dismissMode = true;
        exitAnimationTimer.start();
    }

    function expire() {
        isExiting = true;
        exitAnimationTimer.dismissMode = false;
        exitAnimationTimer.start();
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

        onDismissed: root.dismiss()
        onActionTriggered: action => {
            root.actionTriggered(action);
            root.dismiss();
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: dismissTimer.stop()
        onExited: {
            if (autoDismiss && timeout > 0) {
                dismissTimer.start();
            }
        }
    }
}
