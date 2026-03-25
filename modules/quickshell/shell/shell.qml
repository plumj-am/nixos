import QtQuick
import Quickshell
import Quickshell.Wayland
import "bar"
import "common" as Common
import "services" as Services

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property var modelData
            screen: modelData
        }
    }

    Loader {
        id: launcherLoader
        active: true
        source: "launcher/Launcher.qml"
        onLoaded: {
            item.screen = Quickshell.focusedScreen || Quickshell.screens[0]
        }
    }

    function toggleLauncher() {
        if (launcherLoader.item) {
            launcherLoader.item.isOpen = !launcherLoader.item.isOpen
        }
    }
}
