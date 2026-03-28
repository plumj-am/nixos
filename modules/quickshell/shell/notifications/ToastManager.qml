import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common" as Common
import "."

PanelWindow {
    id: root

    property int maxVisible: 5
    property var activeToasts: []
    property var seenIds: ({})

    color: "transparent"
    visible: activeToasts.length > 0

    anchors {
        right: true
        top: true
        bottom: true
    }

    implicitWidth: 420
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    margins {
        top: Common.Config.data.bar.size
        right: 0
    }

    ColumnLayout {
        id: toastColumn
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 0
        anchors.bottomMargin: 12
        spacing: 0

        Repeater {
            model: root.activeToasts.slice(0, root.maxVisible).reverse()

            NotificationToast {
                Layout.alignment: Qt.AlignRight
                notification: modelData
                skipEntryAnimation: root.seenIds[modelData.id] === true

                onEntryComplete: root.markSeen(notification.id)

                onDismissed: {
                    NotificationServer.dismiss(notification);
                    root.removeToast(notification);
                }

                onExpired: {
                    NotificationServer.expire(notification);
                    root.removeToast(notification);
                }

                onActionTriggered: function (action) {
                    NotificationServer.invokeAction(notification, action);
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Connections {
        target: NotificationServer

        function onNotificationReceived(notification) {
            root.addToast(notification);
        }
    }

    function addToast(notification) {
        const newToasts = activeToasts.slice();
        newToasts.push(notification);
        activeToasts = newToasts;
    }

    function markSeen(notificationId) {
        seenIds[notificationId] = true;
    }

    function removeToast(notification) {
        const newToasts = activeToasts.filter(function (n) {
            return n !== notification;
        });
        activeToasts = newToasts;
    }
}
