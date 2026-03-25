pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property int count: items.length
    readonly property bool hasItems: count > 0
}
