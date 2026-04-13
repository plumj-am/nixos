pragma Singleton
import QtQuick

QtObject {
    readonly property int positionTop: 0
    readonly property int positionBottom: 1
    readonly property int cornerTopLeft: 0
    readonly property int cornerTopRight: 1
    readonly property int networkWired: 0
    readonly property int networkWireless: 1

    function stringToPosition(str) {
        return str === "bottom" ? positionBottom : positionTop;
    }

    function networkToString(value) {
        if (value === networkWired)
            return "wired";
        if (value === networkWireless)
            return "wireless";
        return "unknown";
    }
}
