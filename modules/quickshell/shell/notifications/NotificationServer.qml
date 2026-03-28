pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property ListModel historyModel: ListModel {}

    property NotificationServer server: NotificationServer {
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: function(notification) {
            notification.tracked = !notification.transient
            root.addToHistory(notification)
            root.notificationReceived(notification)
        }
    }

    readonly property int notificationCount: historyModel.count

    signal notificationReceived(var notification)

    function addToHistory(notification) {
        var data = {
            id: notification.id,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            appIcon: notification.appIcon,
            desktopEntry: notification.desktopEntry,
            image: notification.image,
            urgency: notification.urgency,
            time: notification.time,
            actions: notification.actions,
            expireTimeout: notification.expireTimeout
        }
        historyModel.insert(0, { "notificationData": data })
    }

    function removeFromHistory(index) {
        if (index >= 0 && index < historyModel.count) {
            historyModel.remove(index)
        }
    }

    function dismiss(index) {
        removeFromHistory(index)
    }

    function dismissAll() {
        historyModel.clear()
    }

    function invokeAction(notificationData, action) {
        var tracked = server.trackedNotifications.values.find(function(n) { return n.id === notificationData.id })
        if (tracked && action && action.invoke) {
            action.invoke()
        }
    }

    function expire(notificationData) {
        var tracked = server.trackedNotifications.values.find(function(n) { return n.id === notificationData.id })
        if (tracked) {
            tracked.tracked = false
        }
    }
}
