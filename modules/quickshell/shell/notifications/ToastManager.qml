import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../common" as Common
import "."

PanelWindow {
    id: root

    property int maxVisible: 5
    property var seenIds: ({})

    color: "transparent"
    visible: toastModel.count > 0

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

    ListModel {
        id: toastModel
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
            model: toastModel

            NotificationToast {
                Layout.alignment: Qt.AlignRight
                notification: model.notificationData
                skipEntryAnimation: root.seenIds[model.notificationData.id] === true

                onEntryComplete: root.markSeen(notification.id)

                onDismissed: {
                    NotificationServer.dismissById(notification.id);
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
        toastModel.insert(0, { "notificationData": notification });
        while (toastModel.count > maxVisible) {
            toastModel.remove(toastModel.count - 1);
        }
    }

    function markSeen(notificationId) {
        seenIds[notificationId] = true;
        var keys = Object.keys(seenIds);
        while (keys.length > 50) {
            delete seenIds[keys.shift()];
        }
    }

    function removeToast(notification) {
        for (var i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).notificationData === notification) {
                toastModel.remove(i);
                break;
            }
        }
    }
}
