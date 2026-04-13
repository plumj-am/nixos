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

    property int seenCount: 0

    function markAllSeen() {
        seenCount = historyModel.count
    }

    readonly property int unreadCount: historyModel.count - seenCount

    readonly property int maxHistory: 100

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
            actions: notification.actions ? notification.actions.map(a => ({ identifier: a.identifier, text: a.text })) : [],
            expireTimeout: notification.expireTimeout
        }
        historyModel.insert(0, { "notificationData": data })
        while (historyModel.count > maxHistory) {
            historyModel.remove(historyModel.count - 1)
        }
    }

    function removeFromHistory(index) {
        if (index >= 0 && index < historyModel.count) {
            historyModel.remove(index)
        }
    }

    function dismiss(index) {
        removeFromHistory(index)
    }

    function dismissById(id) {
        for (var i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).notificationData.id === id) {
                removeFromHistory(i)
                return
            }
        }
    }

    function dismissAll() {
        historyModel.clear()
        seenCount = 0
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
