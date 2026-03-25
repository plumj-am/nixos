pragma Singleton
import QtQuick

QtObject {
    readonly property int orientationHorizontal: 0
    readonly property int orientationVertical: 1
    readonly property int positionTop: 0
    readonly property int positionBottom: 1
    readonly property int networkWired: 0
    readonly property int networkWireless: 1
    readonly property int networkVirtual: 2

    function stringToPosition(str) {
        return str === "bottom" ? positionBottom : positionTop
    }

    function networkToString(value) {
        if (value === networkWired) return "wired"
        if (value === networkWireless) return "wireless"
        if (value === networkVirtual) return "virtual"
        return "unknown"
    }
}
