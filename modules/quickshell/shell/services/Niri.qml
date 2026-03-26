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

    readonly property var workspaces: niri.workspaces
    readonly property var windows: niri.windows
    readonly property var focusedWindow: niri.focusedWindow

    function focusWorkspace(index) {
        niri.focusWorkspace(index)
    }

    function focusWorkspaceById(id) {
        niri.focusWorkspaceById(id)
    }

    function focusWorkspaceByName(name) {
        niri.focusWorkspaceByName(name)
    }

    function focusWindow(id) {
        niri.focusWindow(id)
    }

    function closeWindow(id) {
        niri.closeWindow(id)
    }

    function closeWindowOrFocused() {
        niri.closeWindowOrFocused()
    }

    function toggleLauncher() {
        launcherToggleRequested()
    }
}
