pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property list<var> notificationHistory: []
    
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

    readonly property int notificationCount: notificationHistory.length

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
        var history = Array.from(notificationHistory)
        history.unshift(data)
        notificationHistory = history
    }

    function removeFromHistory(index) {
        var history = Array.from(notificationHistory)
        history.splice(index, 1)
        notificationHistory = history
    }

    function dismiss(index) {
        removeFromHistory(index)
    }

    function dismissAll() {
        notificationHistory = []
    }

    function invokeAction(notificationData, action) {
        var tracked = server.trackedNotifications.values.find(function(n) { return n.id === notificationData.id })
        if (tracked && action && action.invoke) {
            action.invoke()
        }
    }
}
