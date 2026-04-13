pragma Singleton
import QtQuick
import Niri 0.1

QtObject {
    id: niriWrapper

    signal launcherToggleRequested

    property Niri niri: Niri {
        Component.onCompleted: connect()
        onConnected: console.log("Connected to niri")
        onErrorOccurred: function(error) {
            console.error("Niri error:", error)
        }
    }

    readonly property var focusedWindow: niri.focusedWindow

    function toggleLauncher() {
        launcherToggleRequested()
    }
}
