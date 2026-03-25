pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: niri

    property bool ipcAvailable: false
    property string focusedWindow: ""
    property int focusedWorkspace: 0
    property var workspaces: []

    signal launcherToggleRequested
    signal connected
    signal errorOccurred(string error)

    Process {
        id: checkProcess
        command: ["niri", "msg", "focused-window"]
        
        onExited: function(code, status) {
            ipcAvailable = (code === 0)
            if (ipcAvailable) {
                connected()
            }
        }
    }

    Component.onCompleted: {
        checkProcess.running = true
    }

    function sendCommand(cmd) {
        if (!ipcAvailable) return
        Quickshell.execDetached(["niri", "msg", "action", cmd])
    }

    function toggleLauncher() {
        sendCommand("toggle-launcher")
    }
}
